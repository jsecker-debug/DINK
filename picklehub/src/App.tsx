import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Button } from "@/components/ui/button";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter as Router, Routes, Route, Navigate, Outlet, useNavigate, useLocation } from "react-router-dom";
import { ProductSidebar } from "@/components/ProductSidebar";
import Dashboard from "./pages/Dashboard";
import Feed from "./pages/Feed";
import Schedule from "./pages/Schedule";
import SessionDetail from "./pages/SessionDetail";
import Members from "./pages/Members";
import Rankings from "./pages/Rankings";
import Payments from "./pages/Payments";
import SignUp from "./pages/SignUp";
import SignIn from "./pages/SignIn";
import Index from "./pages/Index";
import Profile from './pages/Profile'
import MarketingHome from './pages/MarketingHome'
import { ProfileButton } from './components/ProfileButton'
import { ClubSelector } from './components/ClubSelector'
import { useSessionStatusUpdater } from './hooks/useSessionStatusUpdater'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import { ClubProvider } from './contexts/ClubContext'

const queryClient = new QueryClient();

// Expose queryClient to window for debugging (development only)
if (process.env.NODE_ENV === 'development') {
  (window as any).queryClient = queryClient;
}

// Auth buttons for unauthenticated users
function AuthButtons() {
  const navigate = useNavigate();
  const location = useLocation();
  
  // Don't show auth buttons on auth pages
  if (location.pathname === '/signin' || location.pathname === '/signup') {
    return null;
  }

  return (
    <div className="flex gap-2">
      <Button variant="outline" onClick={() => navigate('/signin')}>
        Sign In
      </Button>
      <Button onClick={() => navigate('/signup')}>
        Sign Up
      </Button>
    </div>
  );
}

// Main layout for authenticated users
function AuthenticatedLayout() {
  useSessionStatusUpdater();
  const { user } = useAuth();

  // Redirect to marketing page if not authenticated
  if (!user) {
    return <Navigate to="/" replace />;
  }

  return (
    <ProductSidebar>
      <main className="flex-1 overflow-auto bg-background">
        <div className="p-6">
          <div className="flex justify-between items-center mb-6">
            <ClubSelector />
            <ProfileButton />
          </div>
          <div className="bg-card rounded-lg p-6 shadow-sm border border-border">
            <Outlet />
          </div>
        </div>
      </main>
    </ProductSidebar>
  )
}

// Layout for unauthenticated users
function UnauthenticatedLayout() {
  const { user } = useAuth();

  // Redirect to dashboard if authenticated
  if (user) {
    return <Navigate to="/dashboard" replace />;
  }

  return (
    <ProductSidebar>
      <main className="flex-1 overflow-auto bg-background">
        <div className="relative">
          <div className="absolute top-6 right-6 z-10">
            <AuthButtons />
          </div>
          <Outlet />
        </div>
      </main>
    </ProductSidebar>
  )
}

const App = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ClubProvider>
          <TooltipProvider>
            <Router>
              <Routes>
                {/* Unauthenticated routes with sidebar */}
                <Route element={<UnauthenticatedLayout />}>
                  <Route path="/" element={<MarketingHome />} />
                  <Route path="/signup" element={<SignUp />} />
                  <Route path="/signin" element={<SignIn />} />
                </Route>
                
                {/* Main application routes - require authentication */}
                <Route element={<AuthenticatedLayout />}>
                  <Route path="/dashboard" element={<Dashboard />} />
                  <Route path="/feed" element={<Feed />} />
                  <Route path="/schedule" element={<Schedule />} />
                  <Route path="/session/:sessionId" element={<SessionDetail />} />
                  <Route path="/members" element={<Members />} />
                  <Route path="/rankings" element={<Rankings />} />
                  <Route path="/payments" element={<Payments />} />
                  <Route path="/scheduler" element={<Index />} />
                  <Route path="/profile" element={<Profile />} />
                </Route>

                {/* Catch all */}
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </Router>
            <Toaster />
            <Sonner />
          </TooltipProvider>
        </ClubProvider>
      </AuthProvider>
    </QueryClientProvider>
  )
}

export default App;
