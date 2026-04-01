
import { useNavigate } from 'react-router-dom'
import { GradientButton } from '@/components/ui/gradient-button'
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'
import { useIsMobile } from '@/hooks/use-mobile'
import { useAuth } from '@/contexts/AuthContext'
import { LogIn } from 'lucide-react'

export function ProfileButton() {
  const navigate = useNavigate()
  const isMobile = useIsMobile()
  const { user, loading } = useAuth()

  const handleClick = () => {
    if (user) {
      navigate('/profile');
    } else {
      navigate('/signin');
    }
  };

  if (isMobile) {
    return null; // Don't render anything on mobile as it's handled in the sidebar
  }

  if (loading) {
    return (
      <div className="h-10 w-24 bg-muted animate-pulse rounded-md" />
    );
  }

  if (!user) {
    return (
      <GradientButton
        onClick={handleClick}
        className="min-w-0 px-4 py-2 z-50"
      >
        <LogIn className="h-4 w-4 mr-2" />
        <span className="text-sm font-medium">Sign In</span>
      </GradientButton>
    );
  }

  // Get user name and initials
  const userName = user.user_metadata?.full_name || user.email?.split('@')[0] || 'User';
  const initials = userName.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2);

  return (
    <GradientButton
      onClick={handleClick}
      className="min-w-0 px-4 py-2 z-50"
    >
      <Avatar className="h-6 w-6 mr-2 ring-1 ring-offset-1 ring-offset-background ring-border">
        <AvatarImage 
          src={undefined} 
          className="object-cover"
          style={{ width: '100%', height: '100%' }}
        />
        <AvatarFallback className="text-sm bg-secondary text-secondary-foreground">
          {initials}
        </AvatarFallback>
      </Avatar>
      <span className="text-sm font-medium">{userName}</span>
    </GradientButton>
  )
}
