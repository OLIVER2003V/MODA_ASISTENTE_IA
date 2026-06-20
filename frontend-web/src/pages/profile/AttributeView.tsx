import { BodyShapeGraphic } from './components'
import {
  FACE_TYPE_DATA, HAIR_TYPE_DATA, SKIN_TONE_DATA, SKIN_SUBTONE_DATA,
  BODY_TYPE_DATA, HAIR_COLOR_DATA, EYE_COLOR_DATA,
  PREDEFINED_HAIR_VALUES, PREDEFINED_EYE_VALUES,
  STYLE_DATA, CLIMATE_DATA, BUDGET_DATA, GENDER_LABELS,
} from './data'
import type { UserAttribute } from './types'

// Basic color hex lookup (mirrors ColorPreferencesSection)
const COLOR_HEX: Record<string, string> = {
  negro: '#1a1a1a', blanco: '#f5f5f5', gris: '#9e9e9e', beige: '#d4b896',
  camel: '#c2924b', 'marrón': '#92400e', rojo: '#dc2626', rosa: '#f472b6',
  naranja: '#f97316', amarillo: '#facc15', verde: '#16a34a',
  celeste: '#38bdf8', azul: '#2563eb', morado: '#9333ea',
}

const BUDGET_PALETTE: Record<string, { color: string; bg: string }> = {
  LOW:    { color: '#059669', bg: '#ecfdf5' },
  MEDIUM: { color: '#2563eb', bg: '#eff6ff' },
  HIGH:   { color: '#7c3aed', bg: '#f5f3ff' },
  LUXURY: { color: '#d97706', bg: '#fffbeb' },
}

function Card({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`rounded-[24px] overflow-hidden ${className}`}
         style={{ 
           background: '#ffffff', 
           border: '1px solid rgba(226,232,240, 0.8)', 
           boxShadow: '0 12px 32px -12px rgba(15,23,42,0.06), 0 4px 6px -4px rgba(15,23,42,0.02)' 
         }}>
      {children}
    </div>
  )
}

function SectionHeader({ icon, title, gradient }: { icon: string; title: string, gradient: string }) {
  return (
    <div className="flex items-center gap-3 px-6 pt-6 pb-2 relative">
      <div className="w-10 h-10 rounded-2xl flex items-center justify-center text-lg shadow-sm"
           style={{ background: gradient, border: '1px solid rgba(255,255,255,0.5)' }}>
        {icon}
      </div>
      <h2 className="text-[13px] font-black uppercase tracking-[0.15em]" style={{ color: '#0f172a' }}>
        {title}
      </h2>
      <div className="flex-1 h-px ml-2" style={{ background: 'linear-gradient(90deg, rgba(226,232,240,1) 0%, rgba(226,232,240,0) 100%)' }} />
    </div>
  )
}

function StatChip({ label, value, icon }: { label: string; value: string; icon?: string }) {
  return (
    <div className="flex flex-col items-center justify-center px-4 py-3.5 rounded-2xl relative overflow-hidden"
         style={{ 
           background: 'linear-gradient(135deg, #ffffff 0%, #f8fafc 100%)', 
           border: '1px solid rgba(226,232,240,0.8)',
           boxShadow: '0 2px 10px rgba(0,0,0,0.02)',
           minWidth: 84, flex: '1 1 0'
         }}>
      {icon && <span className="text-xl mb-1.5 drop-shadow-sm">{icon}</span>}
      <span className="text-sm font-extrabold tracking-tight" style={{ color: '#0f172a' }}>{value}</span>
      <span className="text-[10px] font-bold uppercase tracking-[0.1em] mt-1" style={{ color: '#64748b' }}>{label}</span>
    </div>
  )
}

export function AttributeView({ attrs }: { attrs: UserAttribute }) {
  const faceData    = FACE_TYPE_DATA.find(f => f.value === attrs.faceType)
  const hairTData   = HAIR_TYPE_DATA.find(h => h.value === attrs.hairType)
  const skinTone    = SKIN_TONE_DATA.find(s => s.value === attrs.skinTone)
  const skinSubtone = SKIN_SUBTONE_DATA.find(s => s.value === attrs.skinSubtone)
  const bodyData    = BODY_TYPE_DATA.find(b => b.value === attrs.bodyType)

  const isHexHair      = !!attrs.hairColor && attrs.hairColor.startsWith('#')
  const isCustomHair   = isHexHair || (!!attrs.hairColor && !PREDEFINED_HAIR_VALUES.includes(attrs.hairColor))
  const hairEntry      = HAIR_COLOR_DATA.find(h => h.value === attrs.hairColor)
  const hairLabel      = isHexHair ? 'Personalizado' : (isCustomHair ? attrs.hairColor : hairEntry?.label)
  const hairHex        = isHexHair ? attrs.hairColor! : (isCustomHair ? null : ('hex' in (hairEntry ?? {}) ? (hairEntry as { hex: string }).hex : null))

  const isCustomEye  = !!attrs.eyeColor && !PREDEFINED_EYE_VALUES.includes(attrs.eyeColor)
  const eyeEntry     = EYE_COLOR_DATA.find(e => e.value === attrs.eyeColor)
  const eyeLabel     = isCustomEye ? attrs.eyeColor : eyeEntry?.label
  const eyeHex       = isCustomEye ? attrs.eyeColor! : ('hex' in (eyeEntry ?? {}) ? (eyeEntry as { hex: string }).hex : '#6B3F1E')

  const climateItem  = CLIMATE_DATA.find(c => c.value === attrs.climate)
  const budgetItem   = BUDGET_DATA.find(b => b.value === attrs.budget)
  const budgetPal    = attrs.budget ? (BUDGET_PALETTE[attrs.budget] ?? BUDGET_PALETTE.MEDIUM) : null

  const genderIcon: Record<string, string> = { MALE: '♂', FEMALE: '♀', NON_BINARY: '⚧', OTHER: '—' }

  return (
    <div className="space-y-6">

      {/* ── Datos físicos ─────────────────────────────────────────── */}
      <Card>
        <SectionHeader icon="---" title="Biometría" gradient="linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%)" />
        <div className="px-6 pb-6 pt-3 space-y-4">
          {/* Stat row */}
          {(attrs.gender || attrs.age || attrs.stature || attrs.weight) && (
            <div className="flex flex-wrap gap-3">
              {attrs.gender    && <StatChip icon={genderIcon[attrs.gender]}  label="Género"   value={GENDER_LABELS[attrs.gender] ?? attrs.gender} />}
              {!!attrs.age     && <StatChip icon="⏳" label="Edad"     value={`${attrs.age} años`} />}
              {!!attrs.stature && <StatChip icon="📏" label="Altura" value={`${attrs.stature} cm`} />}
              {!!attrs.weight  && <StatChip icon="⚖️" label="Peso"     value={`${attrs.weight} kg`} />}
            </div>
          )}

          {/* Body type */}
          {bodyData && (
            <div className="flex items-center gap-5 p-5 rounded-[20px] relative overflow-hidden"
                 style={{ background: 'linear-gradient(135deg, #eef2ff 0%, #e0e7ff 100%)', border: '1px solid rgba(199,210,254,0.6)' }}>
              <div className="absolute right-0 top-0 bottom-0 w-32 bg-gradient-to-l from-white/30 to-transparent pointer-events-none" />
              <div className="w-14 h-20 shrink-0 drop-shadow-md">
                <BodyShapeGraphic type={attrs.bodyType ?? ''} />
              </div>
              <div className="relative z-10">
                <p className="text-[10px] font-bold uppercase tracking-widest mb-1" style={{ color: '#4f46e5' }}>
                  Silueta Corporal
                </p>
                <p className="text-lg font-black tracking-tight" style={{ color: '#1e293b' }}>{bodyData.label}</p>
                <p className="text-xs mt-1 font-medium" style={{ color: '#64748b' }}>{bodyData.desc}</p>
              </div>
            </div>
          )}
        </div>
      </Card>

      {/* ── Apariencia ────────────────────────────────────────────── */}
      {(skinTone || faceData || hairTData || attrs.hairColor || attrs.eyeColor) && (
        <Card>
          <SectionHeader icon="---" title="Apariencia" gradient="linear-gradient(135deg, #fdf4ff 0%, #fae8ff 100%)" />
          <div className="px-6 pb-6 pt-3 space-y-4">

            {/* Skin tone + subtone */}
            {(skinTone || skinSubtone) && (
              <div className="flex gap-3">
                {skinTone && (
                  <div className="flex flex-col items-center gap-2.5 p-4 rounded-[20px] flex-1 text-center"
                       style={{ background: '#f8fafc', border: '1px solid rgba(226,232,240,0.8)' }}>
                    <div className="w-14 h-14 rounded-full relative"
                         style={{ background: skinTone.hex, boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.1), 0 2px 8px rgba(0,0,0,0.05)' }}>
                      <div className="absolute inset-0 rounded-full ring-1 ring-inset ring-black/5" />
                    </div>
                    <div>
                      <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Tono</p>
                      <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{skinTone.label}</p>
                    </div>
                  </div>
                )}
                {skinSubtone && (
                  <div className="flex flex-col items-center gap-2.5 p-4 rounded-[20px] flex-1 text-center"
                       style={{ background: '#f8fafc', border: '1px solid rgba(226,232,240,0.8)' }}>
                    <div className="w-14 h-14 rounded-full relative"
                         style={{ background: skinSubtone.hex, boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.1), 0 2px 8px rgba(0,0,0,0.05)' }}>
                      <div className="absolute inset-0 rounded-full ring-1 ring-inset ring-white/30" />
                    </div>
                    <div>
                      <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Subtono</p>
                      <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{skinSubtone.label}</p>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Face / Hair type */}
            <div className="flex flex-wrap gap-3">
              {faceData && (
                <div className="flex items-center gap-4 p-4 rounded-[20px] flex-1 min-w-[200px]"
                     style={{ background: '#ffffff', border: '1px solid rgba(226,232,240,0.8)', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
                  <img src={faceData.img} alt={faceData.label}
                       className="w-16 h-16 object-cover rounded-xl shadow-sm shrink-0" />
                  <div>
                    <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Rostro</p>
                    <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{faceData.label}</p>
                    <p className="text-xs mt-0.5 leading-snug" style={{ color: '#64748b' }}>{faceData.desc}</p>
                  </div>
                </div>
              )}

              {hairTData && (
                <div className="flex items-center gap-4 p-4 rounded-[20px] flex-1 min-w-[200px]"
                     style={{ background: '#ffffff', border: '1px solid rgba(226,232,240,0.8)', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
                  <img src={hairTData.img} alt={hairTData.label}
                       className="w-16 h-16 object-cover rounded-xl shadow-sm shrink-0" />
                  <div>
                    <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Textura</p>
                    <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{hairTData.label}</p>
                    <p className="text-xs mt-0.5 leading-snug" style={{ color: '#64748b' }}>{hairTData.desc}</p>
                  </div>
                </div>
              )}
            </div>

            {/* Colors: Hair and Eyes */}
            <div className="flex flex-wrap gap-3">
              {attrs.hairColor && (
                <div className="flex items-center gap-4 p-4 rounded-[20px] flex-1 min-w-[150px]"
                     style={{ background: '#f8fafc', border: '1px solid rgba(226,232,240,0.8)' }}>
                  {hairHex
                    ? <div className="w-12 h-12 rounded-full relative"
                           style={{ background: hairHex, boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.2), 0 2px 6px rgba(0,0,0,0.08)' }}>
                        <div className="absolute inset-0 rounded-full ring-1 ring-inset ring-white/10" />
                      </div>
                    : <div className="w-12 h-12 rounded-full flex items-center justify-center bg-white shadow-sm text-xl border border-slate-200">🎨</div>
                  }
                  <div>
                    <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Pelo</p>
                    <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{hairLabel}</p>
                  </div>
                </div>
              )}

              {attrs.eyeColor && (
                <div className="flex items-center gap-4 p-4 rounded-[20px] flex-1 min-w-[150px]"
                     style={{ background: '#f8fafc', border: '1px solid rgba(226,232,240,0.8)' }}>
                  <svg width="48" height="28" viewBox="0 0 48 28" fill="none"
                       style={{ filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.1))', flexShrink: 0 }}>
                    <path d="M 2 14 Q 24 0 46 14 Q 24 28 2 14 Z" fill="white" stroke="#cbd5e1" strokeWidth="1" />
                    <circle cx="24" cy="14" r="9.5" fill={eyeHex} />
                    <circle cx="24" cy="14" r="9.5" fill="none" stroke="rgba(0,0,0,0.25)" strokeWidth="1.5" />
                    <circle cx="24" cy="14" r="4.5" fill="#111" />
                    <circle cx="20" cy="10" r="2.5" fill="white" opacity="0.85" />
                    <circle cx="27" cy="17" r="1" fill="white" opacity="0.5" />
                  </svg>
                  <div>
                    <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Ojos</p>
                    <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{eyeLabel}</p>
                  </div>
                </div>
              )}
            </div>

          </div>
        </Card>
      )}

      {/* ── Estilo ────────────────────────────────────────────────── */}
      {(attrs.preferredStyles?.length || attrs.favoriteColors?.length || attrs.avoidColors?.length) && (
        <Card>
          <SectionHeader icon="---" title="Fashion Profile" gradient="linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%)" />
          <div className="px-6 pb-6 pt-3 space-y-6">

            {/* Style chips with images */}
            {attrs.preferredStyles?.length ? (
              <div>
                <p className="text-[10px] font-bold uppercase tracking-widest mb-3" style={{ color: '#64748b' }}>
                  Aesthetics Preferidas
                </p>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  {attrs.preferredStyles.map(s => {
                    const sd = STYLE_DATA.find(x => x.value === s)
                    return (
                      <div key={s}
                           className="relative rounded-2xl overflow-hidden shadow-sm group"
                           style={{ height: 100, border: '1px solid rgba(0,0,0,0.05)' }}>
                        <img src={sd?.img} alt={sd?.label}
                             className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
                             referrerPolicy="no-referrer"
                             onError={e => { (e.target as HTMLImageElement).style.display = 'none' }} />
                        <div className="absolute inset-0 bg-gradient-to-t from-slate-900/80 via-slate-900/20 to-transparent" />
                        <span className="absolute bottom-3 left-4 right-4 text-xs font-bold tracking-wide text-white drop-shadow-md">
                          {sd?.label ?? s}
                        </span>
                      </div>
                    )
                  })}
                </div>
              </div>
            ) : null}

            {/* Color swatches */}
            {(attrs.favoriteColors?.length || attrs.avoidColors?.length) && (
              <div className="flex flex-wrap gap-8 p-5 rounded-[20px]" style={{ background: '#f8fafc', border: '1px solid rgba(226,232,240,0.6)' }}>
                {attrs.favoriteColors?.length ? (
                  <div className="flex-1 min-w-[150px]">
                    <p className="text-[10px] font-bold uppercase tracking-widest mb-3" style={{ color: '#64748b' }}>
                      Paleta Favorita
                    </p>
                    <div className="flex flex-wrap gap-3">
                      {attrs.favoriteColors.map(c => {
                        const hex = COLOR_HEX[c.toLowerCase()]
                        return hex ? (
                          <div key={c} className="group relative flex flex-col items-center gap-1.5" title={c}>
                            <div className="w-10 h-10 rounded-[14px] shadow-sm transition-transform group-hover:-translate-y-1"
                                 style={{ background: hex, border: '1px solid rgba(0,0,0,0.05)' }}>
                              <div className="absolute inset-0 rounded-[14px] ring-1 ring-inset ring-white/20" />
                            </div>
                            <span className="text-[9px] font-bold uppercase tracking-wider" style={{ color: '#64748b' }}>{c}</span>
                          </div>
                        ) : (
                          <span key={c} className="text-[11px] px-3 py-1.5 rounded-full font-bold uppercase tracking-wider"
                                style={{ background: '#e0e7ff', color: '#4f46e5' }}>{c}</span>
                        )
                      })}
                    </div>
                  </div>
                ) : null}

                {attrs.avoidColors?.length ? (
                  <div className="flex-1 min-w-[150px]">
                    <p className="text-[10px] font-bold uppercase tracking-widest mb-3" style={{ color: '#ef4444' }}>
                      Colores a evitar
                    </p>
                    <div className="flex flex-wrap gap-3">
                      {attrs.avoidColors.map(c => {
                        const hex = COLOR_HEX[c.toLowerCase()]
                        return hex ? (
                          <div key={c} className="group relative flex flex-col items-center gap-1.5" title={c}>
                            <div className="relative w-10 h-10 rounded-[14px] shadow-sm opacity-80"
                                 style={{ background: hex, border: '1px solid rgba(0,0,0,0.05)' }}>
                              <div className="absolute inset-0 rounded-[14px] ring-1 ring-inset ring-red-500/30 bg-red-500/10 flex items-center justify-center">
                                <span className="text-red-500 font-black text-sm drop-shadow-md">✕</span>
                              </div>
                            </div>
                            <span className="text-[9px] font-bold uppercase tracking-wider line-through" style={{ color: '#94a3b8' }}>{c}</span>
                          </div>
                        ) : (
                          <span key={c} className="text-[11px] px-3 py-1.5 rounded-full font-bold uppercase tracking-wider"
                                style={{ background: '#fee2e2', color: '#ef4444' }}>{c}</span>
                        )
                      })}
                    </div>
                  </div>
                ) : null}
              </div>
            )}
          </div>
        </Card>
      )}

      {/* ── Contexto ──────────────────────────────────────────────── */}
      {(attrs.profession || climateItem || attrs.climateCity) && (
        <Card>
          <SectionHeader icon="🌍" title="Estilo de Vida" gradient="linear-gradient(135deg, #fef3c7 0%, #fde68a 100%)" />
          <div className="px-6 pb-6 pt-3 flex flex-wrap gap-4">
            {attrs.profession && (
              <div className="flex items-center gap-4 px-5 py-4 rounded-[20px] flex-1 min-w-[200px]"
                   style={{ background: '#ffffff', border: '1px solid rgba(226,232,240,0.8)', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
                <div className="w-10 h-10 rounded-2xl flex items-center justify-center text-xl bg-slate-50 shadow-sm border border-slate-100">💼</div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Profesión</p>
                  <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{attrs.profession}</p>
                </div>
              </div>
            )}
            {climateItem && (
              <div className="flex items-center gap-4 px-5 py-4 rounded-[20px] flex-1 min-w-[200px]"
                   style={{ background: 'linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%)', border: '1px solid rgba(167,243,208,0.6)' }}>
                <div className="w-10 h-10 rounded-2xl flex items-center justify-center text-2xl bg-white shadow-sm border border-emerald-100/50">{climateItem.icon}</div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#10b981' }}>Clima Regional</p>
                  <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{climateItem.label}</p>
                  <p className="text-[11px] font-medium mt-0.5" style={{ color: '#64748b' }}>{climateItem.desc}</p>
                </div>
              </div>
            )}
            {attrs.climateCity && (
              <div className="flex items-center gap-4 px-5 py-4 rounded-[20px] flex-1 min-w-[200px]"
                   style={{ background: '#ffffff', border: '1px solid rgba(226,232,240,0.8)', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
                <div className="w-10 h-10 rounded-2xl flex items-center justify-center text-xl bg-slate-50 shadow-sm border border-slate-100">📍</div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Locación</p>
                  <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{attrs.climateCity}</p>
                </div>
              </div>
            )}
          </div>
        </Card>
      )}

      {/* ── Compras ───────────────────────────────────────────────── */}
      {attrs.shoppingEnabled && (
        <Card>
          <SectionHeader icon="🛍️" title="Preferencias de Compra" gradient="linear-gradient(135deg, #ecfdf5 0%, #dcfce7 100%)" />
          <div className="px-6 pb-6 pt-3 flex flex-wrap gap-4">
            {attrs.clothingSize && (
              <div className="flex items-center gap-4 px-5 py-4 rounded-[20px] flex-1 min-w-[150px]"
                   style={{ background: '#ffffff', border: '1px solid rgba(226,232,240,0.8)', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
                <div className="w-12 h-12 rounded-[14px] flex items-center justify-center font-black text-lg shadow-sm border border-indigo-100"
                     style={{ background: 'linear-gradient(135deg, #eef2ff 0%, #e0e7ff 100%)', color: '#4f46e5' }}>
                  {attrs.clothingSize}
                </div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Talle Superior</p>
                  <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{attrs.clothingSize}</p>
                </div>
              </div>
            )}
            {!!attrs.shoeSize && (
              <div className="flex items-center gap-4 px-5 py-4 rounded-[20px] flex-1 min-w-[150px]"
                   style={{ background: '#ffffff', border: '1px solid rgba(226,232,240,0.8)', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
                <div className="w-12 h-12 rounded-[14px] flex items-center justify-center text-2xl bg-slate-50 shadow-sm border border-slate-100">👟</div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: '#94a3b8' }}>Calzado</p>
                  <p className="text-sm font-bold" style={{ color: '#1e293b' }}>EU {attrs.shoeSize}</p>
                </div>
              </div>
            )}
            {budgetItem && budgetPal && (
              <div className="flex items-center gap-4 px-5 py-4 rounded-[20px] flex-1 min-w-[200px]"
                   style={{ background: budgetPal.bg, border: `1px solid ${budgetPal.color}40`, boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
                <div className="w-12 h-12 rounded-[14px] flex items-center justify-center text-2xl bg-white shadow-sm"
                     style={{ border: `1px solid ${budgetPal.color}20` }}>{budgetItem.icon}</div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: budgetPal.color }}>Presupuesto</p>
                  <p className="text-sm font-bold" style={{ color: '#1e293b' }}>{budgetItem.label}</p>
                  <p className="text-[11px] font-medium mt-0.5" style={{ color: '#64748b' }}>{budgetItem.desc}</p>
                </div>
              </div>
            )}
          </div>
        </Card>
      )}
    </div>
  )
}
