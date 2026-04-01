import { SignUp } from '../../components/auth/SignUp'
import { useAuth } from '../../contexts/AuthContext'
import { Navigate } from 'react-router-dom'

export default function SignUpPage() {
  const { user, loading } = useAuth()

  if (loading) {
    return <div>Loading...</div>
  }

  if (user) {
    return <Navigate to="/dashboard" replace />
  }

  return <SignUp />
} 