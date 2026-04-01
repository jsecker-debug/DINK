import { ProfileSetup } from '../../components/auth/ProfileSetup'
import { useAuth } from '../../contexts/AuthContext'
import { Navigate } from 'react-router-dom'

export default function ProfileSetupPage() {
  const { user, loading } = useAuth()

  if (loading) {
    return <div>Loading...</div>
  }

  if (!user) {
    return <Navigate to="/auth/sign-in" replace />
  }

  return <ProfileSetup />
} 