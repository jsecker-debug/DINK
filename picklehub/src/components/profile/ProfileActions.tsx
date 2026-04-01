
import { Button } from '@/components/ui/button'
import { GradientButton } from '@/components/ui/gradient-button'

interface ProfileActionsProps {
  onResetPassword: () => void
  onLogout: () => void
}

export function ProfileActions({ onResetPassword, onLogout }: ProfileActionsProps) {
  return (
    <div className="space-y-4">
      <Button 
        type="button" 
        variant="outline" 
        onClick={onResetPassword}
        className="w-full"
      >
        Reset Password
      </Button>
      <GradientButton 
        type="button"
        onClick={onLogout}
        className="w-full gradient-button-red"
      >
        Logout
      </GradientButton>
    </div>
  )
}
