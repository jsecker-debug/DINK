
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'
import { Camera } from 'lucide-react'

interface ProfileAvatarProps {
  avatarUrl: string | null
  firstName: string
  loading: boolean
  onImageSelect: (event: React.ChangeEvent<HTMLInputElement>) => void
}

export function ProfileAvatar({ avatarUrl, firstName, loading, onImageSelect }: ProfileAvatarProps) {
  return (
    <div className="flex flex-col items-center space-y-4">
      <div className="relative group">
        <Avatar className="h-24 w-24 ring-2 ring-offset-2 ring-offset-background ring-muted">
          <AvatarImage 
            src={avatarUrl || undefined} 
            className="object-cover"
            style={{ width: '100%', height: '100%' }}
          />
          <AvatarFallback className="text-lg bg-gradient-to-br from-blue-500 to-purple-500 text-white">
            {firstName[0]?.toUpperCase()}
          </AvatarFallback>
        </Avatar>
        <label 
          htmlFor="avatar-upload" 
          className="absolute bottom-0 right-0 p-1 rounded-full bg-white shadow-lg cursor-pointer 
                   opacity-0 group-hover:opacity-100 transition-opacity duration-200"
        >
          <Camera className="h-4 w-4 text-gray-600" />
        </label>
        <input
          id="avatar-upload"
          type="file"
          accept="image/*"
          onChange={onImageSelect}
          className="hidden"
          disabled={loading}
        />
      </div>
      <p className="text-sm text-gray-500">
        Click to upload or change profile picture
      </p>
    </div>
  )
}
