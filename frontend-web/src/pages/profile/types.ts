export interface UserAttribute {
  id?: string
  gender?: string
  age?: number
  stature?: number
  weight?: number
  bodyType?: string
  skinTone?: string
  skinSubtone?: string
  faceType?: string
  hairColor?: string
  hairType?: string
  eyeColor?: string
  preferredStyles?: string[]
  favoriteColors?: string[]
  avoidColors?: string[]
  profession?: string
  climate?: string
  climateCity?: string
  clothingSize?: string
  shoeSize?: number
  budget?: string
  shoppingEnabled?: boolean
  userId: string
}

export type SetAttr = (k: keyof UserAttribute, v: unknown) => void
