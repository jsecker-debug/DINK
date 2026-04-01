import { useAuth } from '../../contexts/AuthContext'
import { Navigate } from 'react-router-dom'

export default function EmailConfirmationPage() {
  const { user, loading } = useAuth()

  if (loading) {
    return <div>Loading...</div>
  }

  if (!user) {
    return <Navigate to="/auth/sign-in" replace />
  }

  if (user.email_confirmed_at) {
    return <Navigate to="/auth/profile-setup" replace />
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-4 bg-gray-50">
      <div className="w-full max-w-md space-y-4 text-center">
        <h2 className="text-2xl font-bold text-gray-900">Check your email</h2>
        <p className="text-gray-600">
          We've sent you a confirmation link. Please check your email and click the link to activate your account.
        </p>
        <p className="text-sm text-gray-500">
          Once confirmed, you'll be automatically redirected to complete your profile.
        </p>
      </div>
    </div>
  )
} 