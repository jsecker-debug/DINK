import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";
import { useNavigate, useSearchParams } from "react-router-dom";
import { useClub } from "@/contexts/ClubContext";
import { useQueryClient } from "@tanstack/react-query";
import { 
  UserPlus, 
  Mail, 
  Lock, 
  User, 
  Phone, 
  Target,
  Building,
  Check,
  X,
  Gift
} from "lucide-react";

interface SignUpFormData {
  email: string;
  password: string;
  confirmPassword: string;
  firstName: string;
  lastName: string;
  phone: string;
  level: string;
  gender: string;
}

const SignUp = () => {
  const queryClient = useQueryClient();
  const [formData, setFormData] = useState<SignUpFormData>({
    email: "",
    password: "",
    confirmPassword: "",
    firstName: "",
    lastName: "",
    phone: "",
    level: "3.0",
    gender: "M"
  });
  
  const [isLoading, setIsLoading] = useState(false);
  const [step, setStep] = useState(1);
  const [inviteData, setInviteData] = useState<{ token: string; clubName: string; inviterName: string; clubId: string } | null>(null);
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { refreshClubs, setSelectedClubId } = useClub();

  // Check for invite token on component mount
  useEffect(() => {
    const inviteToken = searchParams.get('invite');
    if (inviteToken) {
      checkInviteToken(inviteToken);
    }
  }, [searchParams]);

  const checkInviteToken = async (token: string) => {
    try {
      // First get the basic invitation data
      const { data: invitation, error } = await supabase
        .from('club_invitations')
        .select('*')
        .eq('token', token)
        .eq('status', 'pending')
        .single();

      if (error || !invitation) {
        toast.error('Invalid or expired invitation link');
        return;
      }

      // Check if invitation is expired
      if (new Date(invitation.expires_at) < new Date()) {
        toast.error('This invitation has expired');
        return;
      }

      // Get club information separately
      const { data: club } = await supabase
        .from('clubs')
        .select('name')
        .eq('id', invitation.club_id)
        .single();

      // Get inviter information from user_profiles table (assuming you have it)
      const { data: inviter } = await supabase
        .from('user_profiles')
        .select('first_name, last_name')
        .eq('id', invitation.invited_by)
        .single();

      // Pre-fill email if it matches the invitation
      setFormData(prev => ({
        ...prev,
        email: invitation.email
      }));

      const inviterName = inviter ? `${inviter.first_name} ${inviter.last_name}` : 'Someone';
      const clubName = club?.name || 'Unknown Club';

      setInviteData({
        token: token,
        clubName: clubName,
        inviterName: inviterName,
        clubId: invitation.club_id
      });

      toast.success(`You've been invited to join ${clubName}!`);
    } catch (error) {
      console.error('Error checking invite token:', error);
      toast.error('Error processing invitation');
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const validateStep1 = () => {
    if (!formData.email || !formData.password || !formData.confirmPassword) {
      toast.error("Please fill in all fields");
      return false;
    }
    if (formData.password !== formData.confirmPassword) {
      toast.error("Passwords do not match");
      return false;
    }
    if (formData.password.length < 6) {
      toast.error("Password must be at least 6 characters");
      return false;
    }
    return true;
  };

  const validateStep2 = () => {
    if (!formData.firstName || !formData.lastName || !formData.phone) {
      toast.error("Please fill in all personal information");
      return false;
    }
    return true;
  };

  const handleNext = () => {
    if (step === 1 && validateStep1()) {
      setStep(2);
    }
  };

  const processInvite = async (userId: string) => {
    if (!inviteData) return;

    try {
      // Get the invitation details
      const { data: invitation, error: fetchError } = await supabase
        .from('club_invitations')
        .select('*')
        .eq('token', inviteData.token)
        .eq('status', 'pending')
        .single();

      if (fetchError || !invitation) {
        console.error('Error fetching invitation:', fetchError);
        return;
      }

      // Mark invitation as accepted
      const { error: updateError } = await supabase
        .from('club_invitations')
        .update({
          status: 'accepted',
          accepted_at: new Date().toISOString(),
          accepted_by: userId
        })
        .eq('token', inviteData.token);

      if (updateError) {
        console.error('Error updating invitation:', updateError);
      }

      // Add user to club
      const { error: membershipError } = await supabase
        .from('club_memberships')
        .insert({
          club_id: invitation.club_id,
          user_id: userId,
          role: 'member',
          status: 'active'
        });

      if (membershipError) {
        console.error('Error creating membership:', membershipError);
      } else {
        toast.success(`Successfully joined ${inviteData.clubName}!`);
        
        // Invalidate React Query cache to refresh member data
        queryClient.invalidateQueries({ queryKey: ["participants", invitation.club_id] });
        queryClient.invalidateQueries({ queryKey: ["club-members", invitation.club_id] });
      }
    } catch (error) {
      console.error('Error processing invite:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateStep2()) return;
    
    setIsLoading(true);
    
    try {
      // Create auth user (this will send confirmation email)
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            full_name: `${formData.firstName} ${formData.lastName}`,
            phone: formData.phone,
            level: formData.level,
            gender: formData.gender,
            invite_token: inviteData?.token // Store invite token in user metadata
          }
        }
      });
      
      if (authError) throw authError;

      // Create or update user profile record
      if (authData.user) {
        const { error: profileError } = await supabase
          .from('user_profiles')
          .upsert({
            id: authData.user.id,
            first_name: formData.firstName,
            last_name: formData.lastName,
            email: formData.email,
            phone: formData.phone,
            skill_level: parseFloat(formData.level),
            gender: formData.gender,
            total_games_played: 0,
            wins: 0,
            losses: 0,
            is_active: true
          }, {
            onConflict: 'id'
          });

        if (profileError) {
          console.error('Error creating user profile:', profileError);
          throw new Error('Failed to create user profile');
        }
      }

      // If there's an invite and the user was created successfully, process it
      if (inviteData && authData.user) {
        await processInvite(authData.user.id);
      }
      
      // Success! Account created, redirect to sign-in page
      const successMessage = inviteData 
        ? `Account created! Please check your email to confirm your account. You'll be automatically added to ${inviteData.clubName} once confirmed.`
        : "Account created! Please check your email to confirm your account.";
      
      toast.success(successMessage);
      
      // Redirect to sign-in page with signup flag and invite info
      const redirectUrl = inviteData 
        ? `/signin?signup=true&invite=${inviteData.token}`
        : '/signin?signup=true';
      navigate(redirectUrl);
      
    } catch (error: unknown) {
      console.error('Sign up error:', error);
      const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
      if (errorMessage.includes('User already registered')) {
        toast.error("An account with this email already exists. Please sign in instead.");
        const redirectUrl = inviteData 
          ? `/signin?invite=${inviteData.token}`
          : '/signin';
        navigate(redirectUrl);
      } else {
        toast.error(errorMessage || "Failed to create account");
      }
    } finally {
      setIsLoading(false);
    }
  };

  const renderStep1 = () => (
    <div className="space-y-6">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-card-foreground">Create Account</h2>
        <p className="text-muted-foreground mt-2">Enter your email and password</p>
      </div>
      
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="email" className="flex items-center gap-2">
            <Mail className="h-4 w-4" />
            Email Address
          </Label>
          <Input
            id="email"
            name="email"
            type="email"
            value={formData.email}
            onChange={handleInputChange}
            placeholder="john@example.com"
            className="bg-background border-border"
            required
          />
        </div>
        
        <div className="space-y-2">
          <Label htmlFor="password" className="flex items-center gap-2">
            <Lock className="h-4 w-4" />
            Password
          </Label>
          <Input
            id="password"
            name="password"
            type="password"
            value={formData.password}
            onChange={handleInputChange}
            placeholder="Minimum 6 characters"
            className="bg-background border-border"
            required
          />
        </div>
        
        <div className="space-y-2">
          <Label htmlFor="confirmPassword" className="flex items-center gap-2">
            <Lock className="h-4 w-4" />
            Confirm Password
          </Label>
          <Input
            id="confirmPassword"
            name="confirmPassword"
            type="password"
            value={formData.confirmPassword}
            onChange={handleInputChange}
            placeholder="Confirm your password"
            className="bg-background border-border"
            required
          />
        </div>
      </div>
      
      <Button onClick={handleNext} className="w-full">
        Next Step
      </Button>
    </div>
  );

  const renderStep2 = () => (
    <div className="space-y-6">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-card-foreground">Personal Information</h2>
        <p className="text-muted-foreground mt-2">Tell us about yourself</p>
      </div>
      
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="firstName" className="flex items-center gap-2">
              <User className="h-4 w-4" />
              First Name
            </Label>
            <Input
              id="firstName"
              name="firstName"
              value={formData.firstName}
              onChange={handleInputChange}
              placeholder="John"
              className="bg-background border-border"
              required
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="lastName" className="flex items-center gap-2">
              <User className="h-4 w-4" />
              Last Name
            </Label>
            <Input
              id="lastName"
              name="lastName"
              value={formData.lastName}
              onChange={handleInputChange}
              placeholder="Doe"
              className="bg-background border-border"
              required
            />
          </div>
        </div>
        
        <div className="space-y-2">
          <Label htmlFor="phone" className="flex items-center gap-2">
            <Phone className="h-4 w-4" />
            Phone Number
          </Label>
          <Input
            id="phone"
            name="phone"
            type="tel"
            value={formData.phone}
            onChange={handleInputChange}
            placeholder="+1 (555) 123-4567"
            className="bg-background border-border"
            required
          />
        </div>
        
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="level" className="flex items-center gap-2">
              <Target className="h-4 w-4" />
              Skill Level
            </Label>
            <select
              id="level"
              name="level"
              value={formData.level}
              onChange={handleInputChange}
              className="flex h-9 w-full rounded-md border border-border bg-background px-3 py-1 text-sm text-foreground"
            >
              <option value="2.0">2.0 - Beginner</option>
              <option value="2.5">2.5 - Beginner+</option>
              <option value="3.0">3.0 - Intermediate</option>
              <option value="3.5">3.5 - Intermediate+</option>
              <option value="4.0">4.0 - Advanced</option>
              <option value="4.5">4.5 - Advanced+</option>
              <option value="5.0">5.0 - Expert</option>
            </select>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="gender" className="flex items-center gap-2">
              <User className="h-4 w-4" />
              Gender
            </Label>
            <select
              id="gender"
              name="gender"
              value={formData.gender}
              onChange={handleInputChange}
              className="flex h-9 w-full rounded-md border border-border bg-background px-3 py-1 text-sm text-foreground"
            >
              <option value="M">Male</option>
              <option value="F">Female</option>
              <option value="O">Other</option>
            </select>
          </div>
        </div>
      </div>
      
      <div className="flex gap-3">
        <Button variant="outline" onClick={() => setStep(1)} className="w-full">
          Back
        </Button>
        <Button onClick={handleSubmit} disabled={isLoading} className="w-full">
          {isLoading ? 'Creating Account...' : 'Create Account'}
        </Button>
      </div>
    </div>
  );


  return (
    <div className="space-y-8 p-6">
      {/* Invitation Banner */}
      {inviteData && (
        <Card className="max-w-md mx-auto bg-gradient-to-r from-blue-50 to-indigo-50 border-blue-200">
          <CardContent className="p-6">
            <div className="flex items-center gap-3">
              <Gift className="h-6 w-6 text-blue-600" />
              <div>
                <h3 className="font-semibold text-blue-900">You're Invited!</h3>
                <p className="text-sm text-blue-700 mt-1">
                  <strong>{inviteData.inviterName}</strong> invited you to join{" "}
                  <strong>{inviteData.clubName}</strong>
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Progress Indicator */}
      <div className="flex items-center justify-center space-x-4">
        {[1, 2].map((stepNumber) => (
          <div key={stepNumber} className="flex items-center">
            <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
              step >= stepNumber 
                ? 'bg-primary text-primary-foreground' 
                : 'bg-muted text-muted-foreground'
            }`}>
              {step > stepNumber ? <Check className="h-4 w-4" /> : stepNumber}
            </div>
            {stepNumber < 2 && (
              <div className={`w-12 h-0.5 ml-2 ${
                step > stepNumber ? 'bg-primary' : 'bg-muted'
              }`} />
            )}
          </div>
        ))}
      </div>

      {/* Sign Up Form */}
      <div className="max-w-md mx-auto">
        <Card className="bg-card border-border">
          <CardHeader className="text-center">
            <div className="w-12 h-12 bg-gradient-to-br from-chart-1 to-chart-2 rounded-full flex items-center justify-center mx-auto mb-4">
              <UserPlus className="h-6 w-6 text-white" />
            </div>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit}>
              {step === 1 && renderStep1()}
              {step === 2 && renderStep2()}
            </form>
          </CardContent>
        </Card>
      </div>

      {/* Sign In Link */}
      <div className="text-center">
        <p className="text-muted-foreground">
          Already have an account?{" "}
          <Button 
            variant="link" 
            onClick={() => navigate('/signin')}
            className="p-0 text-primary hover:text-primary/80"
          >
            Sign in here
          </Button>
        </p>
      </div>

      {/* Info Card */}
      <Card className="max-w-md mx-auto bg-card border-border">
        <CardContent className="p-6">
          <h3 className="font-semibold text-card-foreground mb-2">
            {inviteData ? `Joining ${inviteData.clubName}` : 'What happens after signup?'}
          </h3>
          <ul className="space-y-2 text-sm text-muted-foreground">
            <li className="flex items-center gap-2">
              <Check className="h-4 w-4 text-green-500" />
              Your account will be created instantly
            </li>
            {inviteData ? (
              <>
                <li className="flex items-center gap-2">
                  <Check className="h-4 w-4 text-green-500" />
                  You'll be automatically added to {inviteData.clubName}
                </li>
                <li className="flex items-center gap-2">
                  <Check className="h-4 w-4 text-green-500" />
                  Start registering for sessions immediately
                </li>
                <li className="flex items-center gap-2">
                  <Check className="h-4 w-4 text-green-500" />
                  Connect with other members in the club
                </li>
              </>
            ) : (
              <>
                <li className="flex items-center gap-2">
                  <Check className="h-4 w-4 text-green-500" />
                  You can create your own pickleball club
                </li>
                <li className="flex items-center gap-2">
                  <Check className="h-4 w-4 text-green-500" />
                  Or join existing clubs via admin invitations
                </li>
                <li className="flex items-center gap-2">
                  <Check className="h-4 w-4 text-green-500" />
                  Start managing sessions and building your community
                </li>
              </>
            )}
          </ul>
        </CardContent>
      </Card>
    </div>
  );
};

export default SignUp;