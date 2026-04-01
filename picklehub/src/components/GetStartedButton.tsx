import { GradientButton } from "@/components/ui/gradient-button"
import { useNavigate } from "react-router-dom"

export function GetStartedButton() {
  const navigate = useNavigate()

  return (
    <GradientButton
      onClick={() => navigate("/auth/sign-up")}
      className="text-lg font-semibold"
    >
      Get Started
    </GradientButton>
  )
} 