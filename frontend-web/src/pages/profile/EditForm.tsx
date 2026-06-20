import { useState } from 'react'
import type { UserAttribute, SetAttr } from './types'
import { SelfieAnalysisModal } from './SelfieAnalysisModal'
import { GenderSection }           from './sections/GenderSection'
import { PhysicalSection }         from './sections/PhysicalSection'
import { BodyTypeSection }         from './sections/BodyTypeSection'
import { SkinToneSection }         from './sections/SkinToneSection'
import { SkinSubtoneSection }      from './sections/SkinSubtoneSection'
import { FaceTypeSection }         from './sections/FaceTypeSection'
import { HairTypeSection }         from './sections/HairTypeSection'
import { HairColorSection }        from './sections/HairColorSection'
import { EyeColorSection }         from './sections/EyeColorSection'
import { StylesSection }           from './sections/StylesSection'
import { ColorPreferencesSection } from './sections/ColorPreferencesSection'
import { ProfessionSection }       from './sections/ProfessionSection'
import { ClimateSection }          from './sections/ClimateSection'
import { ShoppingSection }         from './sections/ShoppingSection'

interface Props {
  form: Partial<UserAttribute>
  set: SetAttr
  toggleStyle: (s: string) => void
  onSave: () => void
  onCancel: () => void
  saving: boolean
}

export function EditForm({ form, set, toggleStyle, onSave, onCancel, saving }: Props) {
  const [showSelfie, setShowSelfie] = useState(false)

  const handleSelfieApply = (fields: Partial<UserAttribute>) => {
    Object.entries(fields).forEach(([key, value]) => set(key as keyof UserAttribute, value))
  }

  return (
    <div className="space-y-5">
      {showSelfie && (
        <SelfieAnalysisModal
          onApply={handleSelfieApply}
          onClose={() => setShowSelfie(false)}
        />
      )}

      {/* Info banner */}
      <div className="rounded-2xl p-4 flex gap-3 items-start"
           style={{ background: '#eef2ff', border: '1px solid #c7d2fe' }}>
        <span className="text-xl shrink-0">💡</span>
        <div className="flex-1">
          <p className="text-sm font-semibold" style={{ color: '#3730a3' }}>¿Por qué completar tu perfil?</p>
          <p className="text-xs mt-0.5 leading-relaxed" style={{ color: '#4338ca' }}>
            Todos los campos son opcionales, pero cuantos más completes, más precisa y personalizada
            será la IA al recomendarte outfits. ¡Completá lo que puedas!
          </p>
        </div>
        <button
          onClick={() => setShowSelfie(true)}
          className="shrink-0 flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold cursor-pointer transition-all"
          style={{ background: 'linear-gradient(135deg,#4f46e5,#7c3aed)', color: '#fff', border: 'none' }}
        >
          ✨ Completar con foto
        </button>
      </div>

      <GenderSection           form={form} set={set} />
      <PhysicalSection         form={form} set={set} />
      <BodyTypeSection         form={form} set={set} />
      <SkinToneSection         form={form} set={set} />
      <SkinSubtoneSection      form={form} set={set} />
      <FaceTypeSection         form={form} set={set} />
      <HairTypeSection         form={form} set={set} />
      <HairColorSection        form={form} set={set} />
      <EyeColorSection         form={form} set={set} />
      <StylesSection           form={form} toggleStyle={toggleStyle} />
      <ColorPreferencesSection form={form} set={set} />
      <ProfessionSection       form={form} set={set} />
      <ClimateSection          form={form} set={set} />
      <ShoppingSection         form={form} set={set} />

      {/* Save / Cancel */}
      <div className="flex justify-end gap-3 pb-4">
        <button onClick={onCancel} disabled={saving}
          className="px-5 py-2.5 rounded-lg text-sm font-medium cursor-pointer"
          style={{ background: '#f1f5f9', color: '#64748b' }}>
          Cancelar
        </button>
        <button onClick={onSave} disabled={saving}
          className="px-6 py-2.5 rounded-lg text-sm font-medium cursor-pointer flex items-center gap-2"
          style={{ background: saving ? '#a5b4fc' : '#4f46e5', color: '#fff' }}>
          {saving && (
            <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
          )}
          {saving ? 'Guardando…' : 'Guardar cambios'}
        </button>
      </div>
    </div>
  )
}
