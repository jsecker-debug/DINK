import { Link } from 'react-router-dom'

export default function ConfirmationSuccessPage() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-4 bg-gray-50">
      <div className="w-full max-w-md space-y-8 text-center">
        <div className="space-y-4">
          <h1 className="text-3xl font-bold text-gray-900">Email Confirmed!</h1>
          <p className="text-lg text-gray-600">
            Your email has been successfully confirmed.
          </p>
          <p className="text-gray-600">
            Please{' '}
            <Link to="/auth/sign-in" className="font-medium text-blue-600 hover:text-blue-500">
              sign in
            </Link>
            {' '}to continue.
          </p>
        </div>
      </div>
    </div>
  )
} 