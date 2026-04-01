
import { Button } from '@/components/ui/button'

interface ProfileFormProps {
  formData: {
    firstName: string
    lastName: string
    level: string
    gender: string
    phone: string
  }
  onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => void
}

export function ProfileForm({ formData, onChange }: ProfileFormProps) {
  return (
    <>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">First Name</label>
          <input
            name="firstName"
            type="text"
            required
            className="mt-1 block w-full px-3 py-2 border rounded-md"
            value={formData.firstName}
            onChange={onChange}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Last Name</label>
          <input
            name="lastName"
            type="text"
            required
            className="mt-1 block w-full px-3 py-2 border rounded-md"
            value={formData.lastName}
            onChange={onChange}
          />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">DUPR Rating</label>
        <input
          type="text"
          className="mt-1 block w-full px-3 py-2 border rounded-md bg-gray-100"
          value={formData.level}
          disabled
        />
        <p className="mt-1 text-sm text-gray-500">Rating is updated automatically based on game results</p>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Gender</label>
        <select
          name="gender"
          required
          className="mt-1 block w-full px-3 py-2 border rounded-md"
          value={formData.gender}
          onChange={onChange}
        >
          <option value="M">Male</option>
          <option value="F">Female</option>
          <option value="O">Other</option>
        </select>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Phone Number</label>
        <input
          name="phone"
          type="tel"
          required
          className="mt-1 block w-full px-3 py-2 border rounded-md"
          value={formData.phone}
          onChange={onChange}
        />
      </div>
    </>
  )
}
