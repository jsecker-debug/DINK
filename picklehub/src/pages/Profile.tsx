import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { useAuth } from '@/contexts/AuthContext'
import { useNavigate } from 'react-router-dom'
import { 
  User, 
  Mail, 
  Phone, 
  Calendar, 
  Trophy, 
  Target,
  TrendingUp,
  Settings,
  Camera,
  Shield,
  LogOut,
  Key
} from 'lucide-react'
import { format } from 'date-fns'

type UserProfile = {
  id: string
  phone?: string
  bio?: string
  emergency_contact_name?: string
  emergency_contact_phone?: string
  preferences?: any
  created_at: string
  updated_at: string
}


export default function Profile() {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [profileLoading, setProfileLoading] = useState(true)
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null)
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [formData, setFormData] = useState({
    phone: '',
    bio: '',
    emergencyContactName: '',
    emergencyContactPhone: ''
  })

  // Redirect to sign in if not authenticated
  useEffect(() => {
    if (!user) {
      navigate('/signin')
      return
    }
    
    fetchUserProfile()
  }, [user, navigate])

  const fetchUserProfile = async () => {
    if (!user) return
    
    try {
      setProfileLoading(true)
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user.id)
        .single()
      
      if (error) {
        console.error('Error fetching user profile:', error)
        toast.error('Failed to load profile data')
        return
      }
      
      setUserProfile(data)
      setFormData({
        phone: data.phone || '',
        bio: data.bio || '',
        emergencyContactName: data.emergency_contact_name || '',
        emergencyContactPhone: data.emergency_contact_phone || ''
      })
    } catch (error) {
      console.error('Error fetching user profile:', error)
      toast.error('Failed to load profile data')
    } finally {
      setProfileLoading(false)
    }
  }

  const handleImageSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (!event.target.files || event.target.files.length === 0) {
      return
    }
    const file = event.target.files[0]
    const imageUrl = URL.createObjectURL(file)
    // For demo purposes, just set the avatar URL
    setAvatarUrl(imageUrl)
    toast.success("Profile picture updated!")
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user || !userProfile) return
    
    setLoading(true)

    try {
      const { error } = await supabase
        .from('user_profiles')
        .update({
          phone: formData.phone,
          bio: formData.bio,
          emergency_contact_name: formData.emergencyContactName,
          emergency_contact_phone: formData.emergencyContactPhone,
          updated_at: new Date().toISOString()
        })
        .eq('id', user.id)
      
      if (error) {
        console.error('Error updating profile:', error)
        toast.error('Failed to update profile')
        return
      }
      
      // Refresh profile data
      await fetchUserProfile()
      setIsEditing(false)
      
      toast.success("Profile updated successfully!")
    } catch (error) {
      console.error('Error updating profile:', error)
      toast.error("Failed to update profile")
    } finally {
      setLoading(false)
    }
  }

  const handleSignOut = async () => {
    try {
      await signOut()
      navigate('/signin')
      toast.success('Signed out successfully')
    } catch (error) {
      console.error('Error signing out:', error)
      toast.error('Failed to sign out')
    }
  }

  if (!user) {
    return null // Will redirect to signin
  }

  if (profileLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center text-muted-foreground">Loading...</div>
      </div>
    )
  }

  const userName = user.user_metadata?.full_name || user.email?.split('@')[0] || 'User'
  
  const userInitials = userName.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2)

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-foreground">Profile</h1>
        <p className="text-muted-foreground mt-2">
          Manage your personal information and account settings
        </p>
      </div>

      {/* Profile Overview */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Profile Card */}
        <Card className="lg:col-span-1 bg-card border-border">
          <CardContent className="p-6">
            <div className="flex flex-col items-center text-center space-y-4">
              {/* Avatar */}
              <div className="relative">
                <div className="w-24 h-24 rounded-full bg-gradient-to-br from-chart-1 to-chart-2 flex items-center justify-center text-white text-2xl font-bold">
                  {avatarUrl ? (
                    <img 
                      src={avatarUrl} 
                      alt="Profile" 
                      className="w-24 h-24 rounded-full object-cover"
                    />
                  ) : (
                    userInitials
                  )}
                </div>
                <label className="absolute bottom-0 right-0 bg-primary text-primary-foreground p-2 rounded-full cursor-pointer hover:bg-primary/90 transition-colors">
                  <Camera className="h-4 w-4" />
                  <input 
                    type="file" 
                    accept="image/*" 
                    className="hidden" 
                    onChange={handleImageSelect}
                  />
                </label>
              </div>
              
              {/* Name and Level */}
              <div>
                <h2 className="text-xl font-semibold text-card-foreground">
                  {userName}
                </h2>
                <div className="flex items-center justify-center gap-2 mt-2">
                  <Badge variant="outline" className="text-muted-foreground">
                    Member
                  </Badge>
                </div>
              </div>

              {/* Member Since */}
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Calendar className="h-4 w-4" />
                <span>Member since {format(new Date(user.created_at), 'MMMM yyyy')}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Stats Cards - Coming Soon */}
        <div className="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Games Played</p>
                  <p className="text-3xl font-bold text-muted-foreground">-</p>
                  <p className="text-xs text-muted-foreground mt-1">Coming soon</p>
                </div>
                <Trophy className="h-8 w-8 text-chart-1" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Win Rate</p>
                  <p className="text-3xl font-bold text-muted-foreground">-%</p>
                  <p className="text-xs text-muted-foreground mt-1">Coming soon</p>
                </div>
                <Target className="h-8 w-8 text-chart-2" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Total Wins</p>
                  <p className="text-3xl font-bold text-muted-foreground">-</p>
                  <p className="text-xs text-muted-foreground mt-1">Coming soon</p>
                </div>
                <TrendingUp className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Total Losses</p>
                  <p className="text-3xl font-bold text-muted-foreground">-</p>
                  <p className="text-xs text-muted-foreground mt-1">Coming soon</p>
                </div>
                <div className="h-8 w-8 text-red-500 flex items-center justify-center">
                  <TrendingUp className="h-6 w-6 rotate-180" />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Personal Information */}
      <Card className="bg-card border-border">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <User className="h-5 w-5" />
              Personal Information
            </CardTitle>
          </div>
          <Button 
            variant="outline" 
            size="sm"
            onClick={() => setIsEditing(!isEditing)}
          >
            <Settings className="h-4 w-4 mr-2" />
            {isEditing ? 'Cancel' : 'Edit'}
          </Button>
        </CardHeader>
        <CardContent>
          {isEditing ? (
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="phone">Phone</Label>
                  <Input
                    id="phone"
                    name="phone"
                    value={formData.phone}
                    onChange={handleChange}
                    className="bg-background border-border"
                    placeholder="Enter your phone number"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="emergencyContactName">Emergency Contact Name</Label>
                  <Input
                    id="emergencyContactName"
                    name="emergencyContactName"
                    value={formData.emergencyContactName}
                    onChange={handleChange}
                    className="bg-background border-border"
                    placeholder="Emergency contact name"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="emergencyContactPhone">Emergency Contact Phone</Label>
                  <Input
                    id="emergencyContactPhone"
                    name="emergencyContactPhone"
                    value={formData.emergencyContactPhone}
                    onChange={handleChange}
                    className="bg-background border-border"
                    placeholder="Emergency contact phone"
                  />
                </div>
                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="bio">Bio</Label>
                  <Input
                    id="bio"
                    name="bio"
                    value={formData.bio}
                    onChange={handleChange}
                    className="bg-background border-border"
                    placeholder="Tell us about yourself"
                  />
                </div>
              </div>
              <div className="flex gap-3">
                <Button type="submit" disabled={loading}>
                  {loading ? 'Saving...' : 'Save Changes'}
                </Button>
                <Button 
                  type="button" 
                  variant="outline" 
                  onClick={() => setIsEditing(false)}
                >
                  Cancel
                </Button>
              </div>
            </form>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="flex items-center gap-3">
                <User className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Name</p>
                  <p className="font-medium text-card-foreground">{userName}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <Mail className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Email</p>
                  <p className="font-medium text-card-foreground">{user.email}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <Phone className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Phone</p>
                  <p className="font-medium text-card-foreground">{userProfile?.phone || 'Not provided'}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <User className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Bio</p>
                  <p className="font-medium text-card-foreground">{userProfile?.bio || 'Not provided'}</p>
                </div>
              </div>
              {userProfile?.emergency_contact_name && (
                <div className="flex items-center gap-3 md:col-span-2">
                  <Phone className="h-5 w-5 text-muted-foreground" />
                  <div>
                    <p className="text-sm text-muted-foreground">Emergency Contact</p>
                    <p className="font-medium text-card-foreground">
                      {userProfile.emergency_contact_name} 
                      {userProfile.emergency_contact_phone && ` - ${userProfile.emergency_contact_phone}`}
                    </p>
                  </div>
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Account Settings */}
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            Account Settings
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 border border-border rounded-lg">
              <div className="flex items-center gap-3">
                <Key className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="font-medium text-card-foreground">Change Password</p>
                  <p className="text-sm text-muted-foreground">Update your account password</p>
                </div>
              </div>
              <Button variant="outline" size="sm">
                Change
              </Button>
            </div>
            <div className="flex items-center justify-between p-4 border border-border rounded-lg">
              <div className="flex items-center gap-3">
                <LogOut className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="font-medium text-card-foreground">Sign Out</p>
                  <p className="text-sm text-muted-foreground">Sign out of your account</p>
                </div>
              </div>
              <Button variant="outline" size="sm" onClick={handleSignOut}>
                Sign Out
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
