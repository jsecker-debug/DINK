import { useState, useEffect } from "react";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Building2, Crown, Users, Plus, UserPlus } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/contexts/AuthContext";
import { useClub } from "@/contexts/ClubContext";
import { toast } from "sonner";

type Club = {
  id: string
  name: string
  description?: string
  location?: string | string[] // Can be string (legacy) or array
  member_count: number
  role?: string
  status: string
}

type CreateClubData = {
  name: string
  description: string
  locations: string[]
}

type JoinClubData = {
  clubId: string
  message: string
}

export function ClubSelector() {
  const { user } = useAuth()
  const { selectedClub, selectedClubId, setSelectedClubId, userClubs, loading, refreshClubs } = useClub()
  const [allClubs, setAllClubs] = useState<Club[]>([])
  const [createDialogOpen, setCreateDialogOpen] = useState(false)
  const [joinDialogOpen, setJoinDialogOpen] = useState(false)
  const [createFormData, setCreateFormData] = useState<CreateClubData>({ name: '', description: '', locations: [''] })
  const [joinFormData, setJoinFormData] = useState<JoinClubData>({ clubId: '', message: '' })
  const [submitLoading, setSubmitLoading] = useState(false)

  // Helper function to format location display
  const formatLocationDisplay = (location?: string | string[]): string => {
    if (!location) return ''
    if (typeof location === 'string') {
      try {
        const parsed = JSON.parse(location)
        return Array.isArray(parsed) ? parsed.join(' • ') : location
      } catch {
        return location
      }
    }
    return Array.isArray(location) ? location.join(' • ') : ''
  }

  // Helper functions for managing locations
  const addLocation = () => {
    setCreateFormData(prev => ({
      ...prev,
      locations: [...prev.locations, '']
    }))
  }

  const removeLocation = (index: number) => {
    setCreateFormData(prev => ({
      ...prev,
      locations: prev.locations.filter((_, i) => i !== index)
    }))
  }

  const updateLocation = (index: number, value: string) => {
    setCreateFormData(prev => ({
      ...prev,
      locations: prev.locations.map((loc, i) => i === index ? value : loc)
    }))
  }

  useEffect(() => {
    if (!user) return
    fetchAllClubs()
  }, [user])

  const fetchAllClubs = async () => {
    try {
      const { data, error } = await supabase
        .from('clubs')
        .select('id, name, description, location, status')
        .eq('status', 'active')
      
      if (error) {
        console.error('Error fetching all clubs:', error)
        toast.error('Failed to load available clubs')
        return
      }
      
      setAllClubs(data || [])
    } catch (error) {
      console.error('Error fetching all clubs:', error)
    }
  }

  const handleCreateClub = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) return
    
    setSubmitLoading(true)
    try {
      // Create the club
      const { data: club, error: clubError } = await supabase
        .from('clubs')
        .insert({
          name: createFormData.name,
          description: createFormData.description,
          location: createFormData.locations.filter(loc => loc.trim() !== ''),
        })
        .select()
        .single()
      
      if (clubError) {
        console.error('Club creation error:', clubError)
        toast.error(`Failed to create club: ${clubError.message}`)
        return
      }
      
      // Add user as admin of the newly created club
      const { error: membershipError } = await supabase
        .from('club_memberships')
        .insert({
          club_id: club.id,
          user_id: user.id,
          role: 'admin',
          status: 'active'
        })
      
      if (membershipError) {
        console.error('Membership creation error:', membershipError)
        toast.error(`Failed to set up club membership: ${membershipError.message}`)
        return
      }
      
      toast.success('Club created successfully!')
      setCreateDialogOpen(false)
      setCreateFormData({ name: '', description: '', locations: [''] })
      await refreshClubs()
      await fetchAllClubs()
    } catch (error) {
      console.error('Error creating club:', error)
      toast.error('Failed to create club')
    } finally {
      setSubmitLoading(false)
    }
  }

  const handleJoinRequest = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) return
    
    setSubmitLoading(true)
    try {
      // Get user profile data for the request
      const { data: profile } = await supabase
        .from('user_profiles')
        .select('phone')
        .eq('id', user.id)
        .single()
      
      const userData = {
        name: user.user_metadata?.full_name || user.email?.split('@')[0] || 'User',
        email: user.email,
        phone: profile?.phone || '',
        // Add ranking data when available
      }
      
      const { error } = await supabase
        .from('club_join_requests')
        .insert({
          club_id: joinFormData.clubId,
          user_id: user.id,
          message: joinFormData.message,
          user_data: userData
        })
      
      if (error) {
        if (error.code === '23505') { // Unique constraint violation
          toast.error('You have already requested to join this club')
        } else {
          toast.error('Failed to send join request')
        }
        return
      }
      
      toast.success('Join request sent successfully!')
      setJoinDialogOpen(false)
      setJoinFormData({ clubId: '', message: '' })
    } catch (error) {
      console.error('Error sending join request:', error)
      toast.error('Failed to send join request')
    } finally {
      setSubmitLoading(false)
    }
  }

  const getRoleIcon = (role: string) => {
    switch (role) {
      case "admin":
        return <Crown className="h-4 w-4 text-primary" />;
      default:
        return <Users className="h-4 w-4 text-muted-foreground" />;
    }
  };

  const getRoleBadge = (role: string) => {
    switch (role) {
      case "admin":
        return <Badge variant="secondary" className="bg-primary/10 text-primary text-xs">Admin</Badge>;
      default:
        return <Badge variant="outline" className="text-xs">Member</Badge>;
    }
  };

  if (loading) {
    return (
      <div className="w-64 h-10 bg-muted animate-pulse rounded-md" />
    )
  }

  // Show join/create buttons if user has no clubs
  if (userClubs.length === 0) {
    return (
      <div className="flex items-center gap-2">
        <Dialog open={joinDialogOpen} onOpenChange={setJoinDialogOpen}>
          <DialogTrigger asChild>
            <Button variant="outline" size="sm" className="gap-2">
              <UserPlus className="h-4 w-4" />
              Join Club
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle>Join a Club</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleJoinRequest} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="club">Select Club</Label>
                <Select value={joinFormData.clubId} onValueChange={(value) => setJoinFormData(prev => ({ ...prev, clubId: value }))}>
                  <SelectTrigger>
                    <SelectValue placeholder="Choose a club to join" />
                  </SelectTrigger>
                  <SelectContent>
                    {allClubs.map((club) => (
                      <SelectItem key={club.id} value={club.id}>
                        <div>
                          <div className="font-medium">{club.name}</div>
                          {club.location && (
                            <div className="text-sm text-muted-foreground">{formatLocationDisplay(club.location)}</div>
                          )}
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="message">Message to Admin</Label>
                <Textarea
                  id="message"
                  placeholder="Tell the admin why you'd like to join..."
                  value={joinFormData.message}
                  onChange={(e) => setJoinFormData(prev => ({ ...prev, message: e.target.value }))}
                  className="min-h-[80px]"
                />
              </div>
              <div className="flex gap-2 pt-4">
                <Button type="submit" disabled={!joinFormData.clubId || submitLoading} className="flex-1">
                  {submitLoading ? 'Sending...' : 'Send Request'}
                </Button>
                <Button type="button" variant="outline" onClick={() => setJoinDialogOpen(false)}>
                  Cancel
                </Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
        
        <Dialog open={createDialogOpen} onOpenChange={setCreateDialogOpen}>
          <DialogTrigger asChild>
            <Button size="sm" className="gap-2">
              <Plus className="h-4 w-4" />
              Create Club
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Create New Club</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleCreateClub} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="name">Club Name</Label>
                <Input
                  id="name"
                  placeholder="Enter club name"
                  value={createFormData.name}
                  onChange={(e) => setCreateFormData(prev => ({ ...prev, name: e.target.value }))}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  placeholder="Describe your club..."
                  value={createFormData.description}
                  onChange={(e) => setCreateFormData(prev => ({ ...prev, description: e.target.value }))}
                  className="min-h-[80px]"
                />
              </div>
              <div className="space-y-2">
                <Label>Locations</Label>
                <div className="space-y-2">
                  {createFormData.locations.map((location, index) => (
                    <div key={index} className="flex gap-2">
                      <Input
                        placeholder="Club location or address"
                        value={location}
                        onChange={(e) => updateLocation(index, e.target.value)}
                        className="flex-1"
                      />
                      {createFormData.locations.length > 1 && (
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          onClick={() => removeLocation(index)}
                          className="px-3"
                        >
                          ×
                        </Button>
                      )}
                    </div>
                  ))}
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={addLocation}
                    className="w-full"
                  >
                    + Add Another Location
                  </Button>
                </div>
              </div>
              <div className="flex gap-2 pt-4">
                <Button type="submit" disabled={!createFormData.name || submitLoading} className="flex-1">
                  {submitLoading ? 'Creating...' : 'Create Club'}
                </Button>
                <Button type="button" variant="outline" onClick={() => setCreateDialogOpen(false)}>
                  Cancel
                </Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>
    )
  }

  return (
    <div className="flex items-center gap-2">
      <Select value={selectedClubId || ''} onValueChange={setSelectedClubId}>
        <SelectTrigger className="w-64 bg-card border-border hover:bg-accent/50 transition-colors h-10">
          <div className="flex items-center gap-3 min-w-0 w-full">
            <div className="flex-shrink-0">
              {getRoleBadge(selectedClub?.role || "member")}
            </div>
            <div className="flex-1 min-w-0">
              <SelectValue>
                <span className="font-medium text-foreground truncate block text-left">
                  {selectedClub?.name}
                </span>
              </SelectValue>
            </div>
            <Building2 className="h-4 w-4 text-muted-foreground flex-shrink-0" />
          </div>
        </SelectTrigger>
        <SelectContent className="w-64 bg-popover border-border">
          <div className="p-1">
            <div className="text-xs font-medium text-muted-foreground mb-2 px-3 py-2">
              Your Clubs
            </div>
            {userClubs.map((club) => {
              const isSelected = club.id === selectedClubId;
              return (
                <SelectItem 
                  key={club.id} 
                  value={club.id}
                  className={`cursor-pointer focus:bg-accent data-[highlighted]:bg-accent min-h-[60px] relative ${
                    isSelected ? 'bg-primary/10 border-l-2 border-l-primary' : ''
                  }`}
                >
                  <div className="flex items-start gap-3 w-full py-1">
                    <div className="flex-shrink-0 mt-0.5">
                      {getRoleIcon(club.role || 'member')}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className={`font-medium leading-tight mb-1 ${
                        isSelected ? 'text-primary' : 'text-foreground'
                      }`}>
                        {club.name}
                      </div>
                      <div>
                        {getRoleBadge(club.role || 'member')}
                      </div>
                    </div>
                  </div>
                </SelectItem>
              )
            })}
            
            {/* Add Club Options */}
            <div className="border-t border-border mt-1 pt-1">
              <Dialog open={joinDialogOpen} onOpenChange={setJoinDialogOpen}>
                <DialogTrigger asChild>
                  <div className="flex items-center gap-3 px-3 py-2 text-sm text-muted-foreground hover:text-foreground cursor-pointer rounded-sm hover:bg-accent transition-colors">
                    <UserPlus className="h-4 w-4" />
                    <span>Join Club</span>
                  </div>
                </DialogTrigger>
                <DialogContent className="sm:max-w-md">
                  <DialogHeader>
                    <DialogTitle>Join a Club</DialogTitle>
                  </DialogHeader>
                  <form onSubmit={handleJoinRequest} className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="club">Select Club</Label>
                      <Select value={joinFormData.clubId} onValueChange={(value) => setJoinFormData(prev => ({ ...prev, clubId: value }))}>
                        <SelectTrigger>
                          <SelectValue placeholder="Choose a club to join" />
                        </SelectTrigger>
                        <SelectContent>
                          {allClubs.filter(club => !userClubs.some(uc => uc.id === club.id)).map((club) => (
                            <SelectItem key={club.id} value={club.id}>
                              <div>
                                <div className="font-medium">{club.name}</div>
                                {club.location && (
                                  <div className="text-sm text-muted-foreground">{formatLocationDisplay(club.location)}</div>
                                )}
                              </div>
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="message">Message to Admin</Label>
                      <Textarea
                        id="message"
                        placeholder="Tell the admin why you'd like to join..."
                        value={joinFormData.message}
                        onChange={(e) => setJoinFormData(prev => ({ ...prev, message: e.target.value }))}
                        className="min-h-[80px]"
                      />
                    </div>
                    <div className="flex gap-2 pt-4">
                      <Button type="submit" disabled={!joinFormData.clubId || submitLoading} className="flex-1">
                        {submitLoading ? 'Sending...' : 'Send Request'}
                      </Button>
                      <Button type="button" variant="outline" onClick={() => setJoinDialogOpen(false)}>
                        Cancel
                      </Button>
                    </div>
                  </form>
                </DialogContent>
              </Dialog>
              
              <Dialog open={createDialogOpen} onOpenChange={setCreateDialogOpen}>
                <DialogTrigger asChild>
                  <div className="flex items-center gap-3 px-3 py-2 text-sm text-muted-foreground hover:text-foreground cursor-pointer rounded-sm hover:bg-accent transition-colors">
                    <Plus className="h-4 w-4" />
                    <span>Create New Club</span>
                  </div>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Create New Club</DialogTitle>
                  </DialogHeader>
                  <form onSubmit={handleCreateClub} className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="name">Club Name</Label>
                      <Input
                        id="name"
                        placeholder="Enter club name"
                        value={createFormData.name}
                        onChange={(e) => setCreateFormData(prev => ({ ...prev, name: e.target.value }))}
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="description">Description</Label>
                      <Textarea
                        id="description"
                        placeholder="Describe your club..."
                        value={createFormData.description}
                        onChange={(e) => setCreateFormData(prev => ({ ...prev, description: e.target.value }))}
                        className="min-h-[80px]"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label>Locations</Label>
                      <div className="space-y-2">
                        {createFormData.locations.map((location, index) => (
                          <div key={index} className="flex gap-2">
                            <Input
                              placeholder="Club location or address"
                              value={location}
                              onChange={(e) => updateLocation(index, e.target.value)}
                              className="flex-1"
                            />
                            {createFormData.locations.length > 1 && (
                              <Button
                                type="button"
                                variant="outline"
                                size="sm"
                                onClick={() => removeLocation(index)}
                                className="px-3"
                              >
                                ×
                              </Button>
                            )}
                          </div>
                        ))}
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          onClick={addLocation}
                          className="w-full"
                        >
                          + Add Another Location
                        </Button>
                      </div>
                    </div>
                    <div className="flex gap-2 pt-4">
                      <Button type="submit" disabled={!createFormData.name || submitLoading} className="flex-1">
                        {submitLoading ? 'Creating...' : 'Create Club'}
                      </Button>
                      <Button type="button" variant="outline" onClick={() => setCreateDialogOpen(false)}>
                        Cancel
                      </Button>
                    </div>
                  </form>
                </DialogContent>
              </Dialog>
            </div>
          </div>
        </SelectContent>
      </Select>
    </div>
  );
}