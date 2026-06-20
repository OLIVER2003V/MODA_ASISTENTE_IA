export const FACE_TYPE_DATA = [
  { value: 'OVAL',   label: 'Ovalada',    desc: 'Frente ligeramente más ancha que el mentón', img: '/images/face-types/ovalada.png' },
  { value: 'ROUND',  label: 'Redonda',    desc: 'Mejillas llenas, ancho y largo similares',   img: '/images/face-types/redonda.png' },
  { value: 'SQUARE', label: 'Cuadrada',   desc: 'Mandíbula angulosa',                         img: '/images/face-types/cuadrada.png' },
  { value: 'HEART',  label: 'Corazón',    desc: 'Frente ancha, mentón estrecho',              img: '/images/face-types/corazon.png' },
  { value: 'OBLONG', label: 'Alargada',   desc: 'Rostro más largo que ancho',                 img: '/images/face-types/alargada.png' },
]

export const HAIR_TYPE_DATA = [
  { value: 'STRAIGHT', label: 'Lacio',      desc: 'Sin ondas ni rizos, cae recto', img: '/images/hair-types/lacio.png' },
  { value: 'WAVY',     label: 'Ondulado',   desc: 'Ondas suaves y sueltas',         img: '/images/hair-types/ondulado.png' },
  { value: 'CURLY',    label: 'Rizado',     desc: 'Rizos definidos y elásticos',    img: '/images/hair-types/rizado.png' },
  { value: 'COILY',    label: 'Muy rizado', desc: 'Espirales apretadas, afro',      img: '/images/hair-types/muy_rizado.png' },
]

export const STYLE_DATA = [
  { value: 'CASUAL',     label: 'Casual',      desc: 'Cómodo y relajado',      img: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=400&q=80' },
  { value: 'FORMAL',     label: 'Formal',      desc: 'Profesional y elegante', img: 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=400&q=80' },
  { value: 'STREETWEAR', label: 'Streetwear',  desc: 'Urbano y moderno',       img: 'https://images.unsplash.com/photo-1538329972958-465d6d2144ed?auto=format&fit=crop&w=400&q=80' },
  { value: 'BOHEMIAN',   label: 'Bohemio',     desc: 'Libre y artístico',      img: 'https://images.unsplash.com/photo-1595446472774-37c5fc18ce46?auto=format&fit=crop&w=400&q=80' },
  { value: 'MINIMALIST', label: 'Minimalista', desc: 'Simple y atemporal',     img: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=400&q=80' },
  { value: 'SPORTY',     label: 'Deportivo',   desc: 'Activo y funcional',     img: 'https://images.unsplash.com/photo-1483721310020-03333e577078?auto=format&fit=crop&w=400&q=80' },
  { value: 'ELEGANT',    label: 'Elegante',    desc: 'Sofisticado y refinado', img: 'https://images.unsplash.com/photo-1637690048998-1e41c61c254d?auto=format&fit=crop&w=400&q=80' },
]

export const BODY_TYPE_DATA = [
  { value: 'PEAR',              label: 'Pera',           desc: 'Caderas más anchas',  img: '/images/body-types/pera.png' },
  { value: 'RECTANGLE',         label: 'Rectángulo',     desc: 'Proporción recta',    img: '/images/body-types/rectangulo.png' },
  { value: 'HOURGLASS',         label: 'Reloj de arena', desc: 'Cintura marcada',     img: '/images/body-types/reloj.png' },
  { value: 'APPLE',             label: 'Manzana',        desc: 'Mayor volumen medio', img: '/images/body-types/manzana.png' },
  { value: 'INVERTED_TRIANGLE', label: 'Triángulo inv.', desc: 'Hombros más anchos', img: '/images/body-types/triangulo.png' },
]

export const SKIN_TONE_DATA = [
  { value: 'LIGHT',        label: 'Muy clara', hex: '#FDDBB4' },
  { value: 'MEDIUM_LIGHT', label: 'Clara',     hex: '#F5C28A' },
  { value: 'MEDIUM',       label: 'Media',     hex: '#D4A574' },
  { value: 'MEDIUM_DARK',  label: 'Morena',    hex: '#A0694A' },
  { value: 'DARK',         label: 'Oscura',    hex: '#5C3317' },
]

export const SKIN_SUBTONE_DATA = [
  {
    value: 'WARM',
    label: 'Cálido',
    desc: 'Venas verdes o verde-azuladas',
    hex: '#E8A24A',
    tip: 'Tu piel tiene destellos dorados o amarillos. Te quedan genial los tonos tierra, naranja, coral y dorado.',
  },
  {
    value: 'COOL',
    label: 'Frío',
    desc: 'Venas azules o violetas',
    hex: '#7EB5D6',
    tip: 'Tu piel tiene destellos rosados o azulados. Te favorecen el azul, plateado, lavanda y tonos joya.',
  },
  {
    value: 'NEUTRAL',
    label: 'Neutro',
    desc: 'Mezcla difícil de definir',
    hex: '#B8A898',
    tip: 'Tenés una mezcla de ambos subtonos. Casi cualquier color te puede quedar bien, ¡tenés mucha versatilidad!',
  },
]

// Most common natural + dyed colors shown as swatches in the edit form
export const COMMON_HAIR_COLOR_DATA = [
  { value: 'BLACK',       label: 'Negro',          hex: '#1a1a1a' },
  { value: 'DARK_BROWN',  label: 'Castaño oscuro', hex: '#3C1F0F' },
  { value: 'BROWN',       label: 'Castaño',        hex: '#7B4F3A' },
  { value: 'LIGHT_BROWN', label: 'Castaño claro',  hex: '#B08060' },
  { value: 'BLONDE',      label: 'Rubio',          hex: '#E8C97A' },
  { value: 'PLATINUM',    label: 'Platino',        hex: '#F0E6D0', border: '#ccc' },
  { value: 'RED',         label: 'Rojizo',         hex: '#C0392B' },
  { value: 'GRAY',        label: 'Gris',           hex: '#9E9E9E' },
  { value: 'WHITE',       label: 'Blanco',         hex: '#F0F0F0', border: '#ccc' },
]

export const COMMON_HAIR_VALUES = COMMON_HAIR_COLOR_DATA.map(c => c.value)

// Full list kept for backward-compat display in AttributeView
export const HAIR_COLOR_DATA = [
  { value: 'BLACK',       label: 'Negro',          hex: '#1a1a1a' },
  { value: 'DARK_BROWN',  label: 'Castaño oscuro', hex: '#3C1F0F' },
  { value: 'BROWN',       label: 'Castaño',        hex: '#7B4F3A' },
  { value: 'LIGHT_BROWN', label: 'Castaño claro',  hex: '#B08060' },
  { value: 'BLONDE',      label: 'Rubio',          hex: '#E8C97A' },
  { value: 'PLATINUM',    label: 'Platino',        hex: '#F0E6D0', border: '#ccc' },
  { value: 'STRAWBERRY',  label: 'Fresa',          hex: '#E8986A' },
  { value: 'RED',         label: 'Rojo',           hex: '#C0392B' },
  { value: 'COPPER',      label: 'Cobrizo',        hex: '#B87333' },
  { value: 'GRAY',        label: 'Gris',           hex: '#9E9E9E' },
  { value: 'WHITE',       label: 'Blanco',         hex: '#F0F0F0', border: '#ccc' },
  { value: 'BLUE',        label: 'Azul',           hex: '#4169E1' },
  { value: 'PINK',        label: 'Rosa',           hex: '#FF69B4' },
  { value: 'PURPLE',      label: 'Morado',         hex: '#9B59B6' },
  { value: 'GREEN',       label: 'Verde',          hex: '#2ECC71' },
  { value: 'OTHER',       label: 'Otro',           hex: '', isCustom: true as const },
]

export const PREDEFINED_HAIR_VALUES = HAIR_COLOR_DATA
  .filter(c => !('isCustom' in c))
  .map(c => c.value)

export const EYE_COLOR_DATA = [
  { value: 'DARK_BROWN',  label: 'Café oscuro',  hex: '#3B1F0A' },
  { value: 'BROWN',       label: 'Café',         hex: '#6B3F1E' },
  { value: 'LIGHT_BROWN', label: 'Café claro',   hex: '#9E6B40' },
  { value: 'HAZEL',       label: 'Avellana',     hex: '#A0785A' },
  { value: 'AMBER',       label: 'Ámbar',        hex: '#C68B2F' },
  { value: 'BLUE',        label: 'Azul',         hex: '#5B8CB7' },
  { value: 'LIGHT_BLUE',  label: 'Azul claro',   hex: '#89C4E1' },
  { value: 'GREEN',       label: 'Verde',        hex: '#4A7C59' },
  { value: 'LIGHT_GREEN', label: 'Verde claro',  hex: '#7CB87A' },
  { value: 'GRAY',        label: 'Gris',         hex: '#8E9BAA' },
  { value: 'GRAY_BLUE',   label: 'Gris azulado', hex: '#7B8FA6' },
  { value: 'BLACK',       label: 'Negro',        hex: '#1a1a1a' },
  { value: 'OTHER',       label: 'Otro',         hex: '', isCustom: true as const },
]

export const PREDEFINED_EYE_VALUES = EYE_COLOR_DATA
  .filter(c => !('isCustom' in c))
  .map(c => c.value)

// Most common eye colors shown as eye-shaped swatches in the edit form
export const COMMON_EYE_COLOR_DATA = [
  { value: 'DARK_BROWN',  label: 'Café oscuro',  hex: '#3B1F0A' },
  { value: 'BROWN',       label: 'Café',         hex: '#6B3F1E' },
  { value: 'LIGHT_BROWN', label: 'Café claro',   hex: '#9E6B40' },
  { value: 'HAZEL',       label: 'Avellana',     hex: '#A0785A' },
  { value: 'AMBER',       label: 'Ámbar',        hex: '#C68B2F' },
  { value: 'BLUE',        label: 'Azul',         hex: '#5B8CB7' },
  { value: 'LIGHT_BLUE',  label: 'Azul claro',   hex: '#89C4E1' },
  { value: 'GREEN',       label: 'Verde',        hex: '#4A7C59' },
  { value: 'GRAY',        label: 'Gris',         hex: '#8E9BAA' },
  { value: 'BLACK',       label: 'Negro',        hex: '#1a1a1a' },
]

export const COMMON_EYE_VALUES = COMMON_EYE_COLOR_DATA.map(c => c.value)

export const CLIMATE_DATA = [
  { value: 'TROPICAL',    label: 'Tropical',    icon: '🌴', desc: 'Caluroso y húmedo' },
  { value: 'DRY',         label: 'Seco',        icon: '☀️', desc: 'Calor sin humedad' },
  { value: 'TEMPERATE',   label: 'Templado',    icon: '🌤️', desc: 'Estaciones marcadas' },
  { value: 'CONTINENTAL', label: 'Continental', icon: '❄️', desc: 'Inviernos fríos' },
  { value: 'POLAR',       label: 'Polar',       icon: '🧊', desc: 'Extremadamente frío' },
]

export const BUDGET_DATA = [
  { value: 'LOW',    label: 'Económico', icon: '💰', desc: 'Marcas accesibles' },
  { value: 'MEDIUM', label: 'Moderado',  icon: '💳', desc: 'Balance calidad-precio' },
  { value: 'HIGH',   label: 'Premium',   icon: '💎', desc: 'Marcas de diseñador' },
  { value: 'LUXURY', label: 'Lujo',      icon: '👑', desc: 'Alta costura' },
]

export const CLOTHING_SIZES = ['XS', 'S', 'M', 'L', 'XL', 'XXL']

export const GENDER_LABELS: Record<string, string> = {
  MALE: 'Masculino',
  FEMALE: 'Femenino',
  NON_BINARY: 'No binario',
  OTHER: 'Prefiero no decir',
}
