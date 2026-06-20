import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { AiService } from 'src/features/ai/ai.service';
import { NotificationsService } from 'src/common/notifications/notifications.service';

@Injectable()
export class ChatService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly aiService: AiService,
    private readonly push: NotificationsService,
  ) {}

  async getConversationsByUser(userId: string, page: number = 1, limit: number = 10) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
      this.prisma.conversation.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          messages: { orderBy: { createdAt: 'asc' } },
          outfit: {
            include: {
              garmentOutfits: { include: { garment: true }, orderBy: { order: 'asc' } },
            },
          },
        },
      }),
      this.prisma.conversation.count({ where: { userId } }),
    ]);

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async startConversation(userId: string, lat?: number, lon?: number) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    const userAttr = await this.prisma.userAttribute.findFirst({ where: { userId } });

    // Auto-fetch real-time weather: coords > climateCity > profile climate
    let initialWeather: string | null = null;
    let weatherNote = '';

    if (lat != null && lon != null) {
      const fetched = await this.fetchCurrentWeather(`${lat},${lon}`);
      if (fetched) {
        initialWeather = fetched;
        weatherNote = ` Donde estás ahora hay ${fetched}.`;
      }
    }
    if (!initialWeather && userAttr?.climateCity) {
      const fetched = await this.fetchCurrentWeather(userAttr.climateCity);
      if (fetched) {
        initialWeather = fetched;
        weatherNote = ` En ${userAttr.climateCity} ahora hay ${fetched}.`;
      }
    }
    if (!initialWeather && userAttr?.climate) {
      initialWeather = userAttr.climate;
    }

    return this.prisma.conversation.create({
      data: {
        userId,
        status: 'CHATTING',
        weather: initialWeather,
        messages: {
          create: {
            content: `¡Hola! ✨ Soy tu estilista personal.${weatherNote} Cuéntame, ¿para qué ocasión te estás preparando?`,
            role: 'ASSISTANT',
          },
        },
      },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
  }

  private async fetchCurrentWeather(city: string): Promise<string | null> {
    try {
      const url = `https://wttr.in/${encodeURIComponent(city)}?format=%C,+%t&m&lang=es`;
      const res = await fetch(url, { signal: AbortSignal.timeout(4_000) });
      if (!res.ok) return null;
      const text = (await res.text()).trim();
      return text.length > 2 ? text : null;
    } catch {
      return null;
    }
  }

  async sendMessage(userId: string, conversationId: string, content: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
    if (!conversation) throw new NotFoundException('Conversación no encontrada');
    if (conversation.userId !== userId) throw new ForbiddenException('No tienes acceso a esta conversación');

    if (conversation.status === 'AWAITING_FACE_IMAGE') {
      throw new BadRequestException('Usa el botón de cámara para subir tu foto de rostro.');
    }

    if (conversation.status === 'GENERATING') {
      throw new BadRequestException('Estoy generando tu outfit, por favor espera un momento...');
    }

    // Guardar mensaje del usuario
    await this.prisma.message.create({
      data: { content, role: 'USER', conversationId },
    });

    // Cargar perfil y prendas del usuario
    const [userAttr, userWithClosets] = await Promise.all([
      this.prisma.userAttribute.findFirst({ where: { userId: conversation.userId } }),
      this.prisma.user.findUnique({
        where: { id: conversation.userId },
        include: { closets: { include: { garments: true } } },
      }),
    ]);

    const allGarments = userWithClosets?.closets.flatMap((c) => c.garments) ?? [];
    const hasOutfit   = !!conversation.outfitId;

    // Historial completo incluyendo el mensaje recién guardado
    const allMessages = [
      ...conversation.messages,
      { role: 'USER' as const, content },
    ];

    // Gemini decide qué hacer
    const ai = await this.aiService.fashionChat({
      messages:     allMessages,
      userProfile:  userAttr,
      garments:     allGarments,
      hasOutfit,
      savedEvent:   conversation.event,
      savedWeather: conversation.weather,
    });

    const effectiveWeather = conversation.weather ?? userAttr?.climate ?? null;

    // ── Guardia: si la IA quiere generar outfit y ya hay uno, verificar que
    // el usuario realmente lo pidió (no fue una inferencia errónea).
    // Si el mensaje del usuario no pide explícitamente otro outfit → chat.
    if (ai.action === 'generate_outfit' && hasOutfit) {
      const lastAssistantMsg = conversation.messages.filter(m => m.role === 'ASSISTANT').at(-1)?.content ?? '';
      const aiPromisedGeneration = /voy a (generar|armar|crear)|vamos a generar|te (voy a|armo|creo) (el|un) outfit|generar.*outfit|armar.*outfit|creo.*outfit/i.test(lastAssistantMsg);
      const userConfirmed = /^(s[ií]|si|sí|yes|dale|ok|okey|claro|perfecto|bueno|va|genial|adelante|hazlo|generalo|gen[eé]ralo|está bien|de acuerdo|listo|vamos|venga)\b/i.test(content.trim());
      const explicitRetry =
        /otro|diferente|cambiar|no me gusta|no.*gust|opci[oó]n|alternativa|m[aá]s (elegante|formal|casual|abrigado|fresco|c[oó]modo|arreglado)|nuevo outfit|dame otro|quiero otro|mu[eé]strame otro|(dame|armame|generame|hazme|creame|quiero|y) .*outfit|si hace fr[ií]o|si hace calor/i.test(content) ||
        (aiPromisedGeneration && userConfirmed);
      if (!explicitRetry) {
        console.log('[chat.service] IA intentó generate_outfit pero usuario no lo pidió explícitamente → convirtiendo a chat');
        ai.action = 'chat';
        // Si el bot decía "te voy a generar...", lo cambiamos para no confundir al usuario prometiendo falsas acciones
        if (/voy a (generar|armar|crear)|vamos a generar|te (voy a|armo|creo)/i.test(ai.reply)) {
          ai.reply = '¿Te gustaría que te arme un outfit diferente con esas características? Confírmame para generarlo ✨';
        }
      }
    }

    // ── Corrección 2: forzar generate_outfit si la IA preguntó el clima (que ya tenemos) ──
    if (ai.action === 'chat' && !hasOutfit && effectiveWeather) {
      const detectedEvent = ai.event ?? conversation.event ?? content;
      const replyAskingWeather = /clima|temperatura|tiempo (que hace|habrá)|calor|frío|lluvi/i.test(ai.reply);

      if (replyAskingWeather || conversation.event) {
        console.log('[chat.service] Corrección clima: forzando generate_outfit. evento=%s clima=%s', detectedEvent, effectiveWeather);
        ai.action  = 'generate_outfit';
        ai.event   = detectedEvent;
        ai.weather = effectiveWeather;
        ai.reply   = `¡Perfecto! Voy a armar tu outfit para ${detectedEvent} ahora mismo ✨`;
      } else if (conversation.messages.length <= 3 && !conversation.event) {
        console.log('[chat.service] Corrección early: asumiendo mensaje como evento. evento=%s clima=%s', content, effectiveWeather);
        ai.action  = 'generate_outfit';
        ai.event   = content;
        ai.weather = effectiveWeather;
        if (replyAskingWeather) {
          ai.reply = `¡Perfecto! Con eso ya tengo todo para tu outfit ✨`;
        }
      }
    }

    switch (ai.action) {
      case 'generate_outfit': {
        // Para nuevo outfit: usa el evento/clima ya guardados si la IA no envió nuevos
        const event   = ai.event   ?? conversation.event   ?? 'un evento especial';
        const weather = ai.weather ?? conversation.weather ?? userAttr?.climate ?? 'templado';

        // Guardar la respuesta conversacional primero
        await this.prisma.message.create({
          data: { content: ai.reply, role: 'ASSISTANT', conversationId },
        });

        await this.prisma.conversation.update({
          where: { id: conversationId },
          data: { event, weather, status: 'GENERATING' },
        });

        try {
          const result = await this.aiService.generateOutfit({
            userId: conversation.userId,
            event,
            weather,
          });

          await this.prisma.conversation.update({
            where: { id: conversationId },
            data: { outfitId: result.outfit.id, status: 'CHATTING' },
          });

          await this.prisma.message.create({
            data: {
              content:
                `✨ **${result.outfit.name}**\n${result.outfit.description ?? ''}\n\n` +
                `¿Qué te parece? Si quieres también puedo recomendarte un peinado que combine perfectamente 💇`,
              role: 'ASSISTANT',
              conversationId,
            },
          });
          this.sendOutfitReadyPush(conversation.userId, result.outfit.name ?? 'Tu nuevo outfit');
        } catch (err) {
          // ── Retry automático una vez antes de mostrar error ──────────────
          console.warn('[chat.service] generateOutfit falló, reintentando...', (err as Error).message.slice(0, 80));
          try {
            const result2 = await this.aiService.generateOutfit({ userId: conversation.userId, event, weather });
            await this.prisma.conversation.update({
              where: { id: conversationId },
              data: { outfitId: result2.outfit.id, status: 'CHATTING' },
            });
            await this.prisma.message.create({
              data: {
                content:
                  `✨ **${result2.outfit.name}**\n${result2.outfit.description ?? ''}\n\n` +
                  `¿Qué te parece? Si quieres también puedo recomendarte un peinado 💇`,
                role: 'ASSISTANT',
                conversationId,
              },
            });
            this.sendOutfitReadyPush(conversation.userId, result2.outfit.name ?? 'Tu nuevo outfit');
          } catch {
            await this.prisma.conversation.update({
              where: { id: conversationId },
              data: { status: 'CHATTING' },
            });
            await this.prisma.message.create({
              data: {
                content: 'Lo siento, los servicios de IA están muy ocupados ahora mismo 😅 Escríbeme en un momento e intento de nuevo.',
                role: 'ASSISTANT',
                conversationId,
              },
            });
          }
        }
        break;
      }

      case 'request_face_photo': {
        await this.prisma.conversation.update({
          where: { id: conversationId },
          data: { status: 'AWAITING_FACE_IMAGE' },
        });
        await this.prisma.message.create({
          data: { content: ai.reply, role: 'ASSISTANT', conversationId },
        });
        break;
      }

      default: {
        await this.prisma.message.create({
          data: { content: ai.reply, role: 'ASSISTANT', conversationId },
        });
        break;
      }
    }

    return this.getConversationWithRelations(conversationId);
  }

  async handleFaceImage(userId: string, conversationId: string, file: Express.Multer.File) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });
    if (!conversation) throw new NotFoundException('Conversación no encontrada');
    if (conversation.userId !== userId) throw new ForbiddenException('No tienes acceso a esta conversación');

    if (conversation.status !== 'AWAITING_FACE_IMAGE') {
      throw new BadRequestException('La conversación no espera una imagen de rostro en este momento.');
    }

    await this.prisma.message.create({
      data: { content: '[Imagen de rostro enviada]', role: 'USER', conversationId },
    });

    const hairstyles = await this.prisma.hairstyle.findMany();

    if (hairstyles.length === 0) {
      await this.prisma.conversation.update({
        where: { id: conversationId },
        data: { status: 'CHATTING' },
      });
      await this.prisma.message.create({
        data: {
          content: 'Aún no hay peinados en el catálogo, pero tu outfit está listo. ¿Puedo ayudarte con algo más?',
          role: 'ASSISTANT',
          conversationId,
        },
      });
      return this.getConversationWithRelations(conversationId);
    }

    try {
      const result = await this.aiService.recommendHairstyle(
        file.buffer,
        file.mimetype,
        hairstyles.map((h) => ({ id: h.id, description: h.description })),
      );

      const recommended = hairstyles.find((h) => h.id === result.hairstyleId);

      await this.prisma.conversation.update({
        where: { id: conversationId },
        data: { status: 'CHATTING' },
      });

      await this.prisma.message.create({
        data: {
          content:
            `**Peinado recomendado:**\n\n${recommended?.description ?? 'Peinado seleccionado'}\n\n` +
            `**¿Por qué este peinado?**\n${result.explanation}\n\n` +
            `¿Qué te gustaría hacer ahora? Puedo **sugerirte otro outfit** para una ocasión diferente, o si prefieres, **contarte más sobre cómo lucir este peinado** con tu ropa 💇✨`,
          role: 'ASSISTANT',
          conversationId,
        },
      });

      const conv = await this.getConversationWithRelations(conversationId);
      return { ...conv, recommendedHairstyle: recommended ?? null };
    } catch {
      await this.prisma.conversation.update({
        where: { id: conversationId },
        data: { status: 'CHATTING' },
      });
      await this.prisma.message.create({
        data: {
          content: 'No pude analizar la imagen ahora mismo 😕 Pero tu outfit sigue listo. ¿Puedo ayudarte con algo más?',
          role: 'ASSISTANT',
          conversationId,
        },
      });
      return this.getConversationWithRelations(conversationId);
    }
  }

  private async getConversationWithRelations(conversationId: string) {
    return this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        messages: { orderBy: { createdAt: 'asc' } },
        outfit: {
          include: {
            garmentOutfits: { include: { garment: true }, orderBy: { order: 'asc' } },
          },
        },
      },
    });
  }

  async deleteConversation(userId: string, conversationId: string) {
    const conversation = await this.prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conversation) throw new NotFoundException('Conversación no encontrada');
    if (conversation.userId !== userId) throw new ForbiddenException('No tienes permiso para eliminar esta conversación');

    // Prisma se encarga del borrado en cascada (mensajes) si tu schema de base de datos tiene onDelete: Cascade
    await this.prisma.conversation.delete({ where: { id: conversationId } });
    return { success: true, message: 'Conversación eliminada correctamente' };
  }

  async sendAudioMessage(userId: string, conversationId: string, file: Express.Multer.File) {
    const text = await this.aiService.transcribeAudio(file.buffer, file.mimetype);
    if (!text || text.trim().length === 0) {
      throw new BadRequestException('No se pudo transcribir el audio. Intenta hablar más claramente.');
    }
    return this.sendMessage(userId, conversationId, text.trim());
  }

  private sendOutfitReadyPush(userId: string, outfitName: string): void {
    this.prisma.user.findUnique({ where: { id: userId }, select: { fcmToken: true } })
      .then(user => {
        if (user?.fcmToken) {
          return this.push.sendNotification({
            token: user.fcmToken,
            title: '✨ ¡Tu outfit está listo!',
            body: outfitName,
            data: { type: 'outfit_ready' },
          });
        }
      })
      .catch(() => null);
  }
}
