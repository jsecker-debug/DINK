import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Calendar as CalendarComponent } from "@/components/ui/calendar";
import { 
  ArrowLeft, 
  Calendar, 
  MapPin, 
  Users, 
  Clock,
  Settings,
  Play,
  CheckCircle,
  XCircle,
  UserPlus,
  UserMinus,
  Trash2
} from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";
import { useSessions } from "@/hooks/useSessions";
import { useSessionSchedule, useDeleteSessionSchedule } from "@/hooks/useSessionSchedule";
import { useSessionRegistrations, useUserSessionRegistration, useRegisterForSession, useUnregisterFromSession } from "@/hooks/useSessionRegistration";
import { useAuth } from "@/contexts/AuthContext";
import { useClub } from "@/contexts/ClubContext";
import CourtDisplayWithScoring from "@/components/CourtDisplayWithScoring";
import DownloadPdfButton from "@/components/DownloadPdfButton";
import SessionScheduleDialog from "@/components/session/SessionScheduleDialog";
import TemporaryParticipantManager from "@/components/session/TemporaryParticipantManager";
import { useTemporaryParticipants } from "@/hooks/useTemporaryParticipants";
import { supabase } from "@/lib/supabase";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

const SessionDetail = () => {
  const { sessionId } = useParams<{ sessionId: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { selectedClub } = useClub();
  const queryClient = useQueryClient();
  const [scheduleDialogOpen, setScheduleDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  
  // Edit form states
  const [editDate, setEditDate] = useState<Date>();
  const [editVenue, setEditVenue] = useState<string>("");
  const [editCost, setEditCost] = useState<string>("");
  const [editMaxParticipants, setEditMaxParticipants] = useState<number>(16);
  const [editStartTime, setEditStartTime] = useState<string>("18:00");
  const [editEndTime, setEditEndTime] = useState<string>("20:00");
  
  // Admin status
  const [isAdmin, setIsAdmin] = useState(false);
  
  const { data: sessions, isLoading: isLoadingSessions } = useSessions();
  const { data: scheduleData, isLoading: isLoadingSchedule } = useSessionSchedule(sessionId || null);
  const { data: registrations, isLoading: isLoadingRegistrations } = useSessionRegistrations(sessionId || '');
  const { data: userRegistration } = useUserSessionRegistration(sessionId || '');
  const { data: temporaryParticipants = [] } = useTemporaryParticipants(sessionId || '');
  const registerMutation = useRegisterForSession();
  const unregisterMutation = useUnregisterFromSession();
  const deleteScheduleMutation = useDeleteSessionSchedule();

  const session = sessions?.find(s => s.id.toString() === sessionId);
  
  // Initialize edit form when session data loads
  useState(() => {
    if (session) {
      const sessionDate = new Date(session.Date);
      setEditDate(sessionDate);
      setEditVenue(session.Venue);
      setEditCost(session.fee_per_player?.toString() || "0");
      setEditMaxParticipants(session.max_participants || 16);
      
      // Extract time from session date
      const startHour = sessionDate.getHours().toString().padStart(2, '0');
      const startMinute = sessionDate.getMinutes().toString().padStart(2, '0');
      setEditStartTime(`${startHour}:${startMinute}`);
      
      // Default end time to 2 hours later
      const endDateTime = new Date(sessionDate);
      endDateTime.setHours(endDateTime.getHours() + 2);
      const endHour = endDateTime.getHours().toString().padStart(2, '0');
      const endMinute = endDateTime.getMinutes().toString().padStart(2, '0');
      setEditEndTime(`${endHour}:${endMinute}`);
    }
  });
  
  // Check admin status
  useState(() => {
    const checkAdminStatus = async () => {
      if (!user || !selectedClub?.id) return;
      
      const { data } = await supabase
        .from('club_memberships')
        .select('role')
        .eq('user_id', user.id)
        .eq('club_id', selectedClub.id)
        .single();
      
      setIsAdmin(data?.role === 'admin');
    };
    
    if (user && selectedClub?.id) {
      checkAdminStatus();
    }
  }, [user, selectedClub?.id]);
  
  // Calculate registration stats
  const registeredUsers = registrations?.filter(r => r.status === 'registered') || [];
  const waitlistUsers = registrations?.filter(r => r.status === 'waitlist') || [];
  const totalPlayers = registeredUsers.length + temporaryParticipants.length;
  const maxParticipants = session?.max_participants || 16;
  const isSessionFull = registeredUsers.length >= maxParticipants;
  const isUserRegistered = !!userRegistration && ['registered', 'waitlist'].includes(userRegistration.status);

  const handleRegister = () => {
    if (!sessionId || !session) return;
    registerMutation.mutate({ 
      sessionId: session.id, 
      session: {
        max_participants: session.max_participants,
        fee_per_player: session.fee_per_player
      }
    });
  };

  const handleUnregister = () => {
    if (!sessionId || !session) return;
    unregisterMutation.mutate({ sessionId: session.id });
  };

  const handleDeleteSchedule = () => {
    if (!sessionId) return;
    if (confirm("Are you sure you want to delete the current schedule? This action cannot be undone.")) {
      deleteScheduleMutation.mutate(sessionId);
    }
  };
  
  // Helper function to get club locations
  const getClubLocations = (): string[] => {
    if (!selectedClub?.location) return []
    
    // Handle both string (legacy) and array formats
    if (typeof selectedClub.location === 'string') {
      try {
        const parsed = JSON.parse(selectedClub.location)
        return Array.isArray(parsed) ? parsed : [selectedClub.location]
      } catch {
        return [selectedClub.location]
      }
    }
    
    return Array.isArray(selectedClub.location) ? selectedClub.location : []
  }
  
  // Update session mutation
  const updateSession = useMutation({
    mutationFn: async () => {
      if (!sessionId || !editDate || !editVenue) {
        throw new Error('Missing required fields');
      }
      
      // Combine date with start and end times
      const startDateTime = new Date(editDate);
      const [startHour, startMinute] = editStartTime.split(':').map(Number);
      startDateTime.setHours(startHour, startMinute, 0, 0);
      
      const endDateTime = new Date(editDate);
      const [endHour, endMinute] = editEndTime.split(':').map(Number);
      endDateTime.setHours(endHour, endMinute, 0, 0);
      
      // If end time is before start time, assume it's the next day
      if (endDateTime <= startDateTime) {
        endDateTime.setDate(endDateTime.getDate() + 1);
      }
      
      const costNumber = parseFloat(editCost);
      if (isNaN(costNumber) || costNumber < 0) {
        throw new Error('Please enter a valid cost');
      }
      
      const updateData: any = {
        Date: startDateTime.toISOString(),
        Venue: editVenue,
        fee_per_player: costNumber,
        max_participants: editMaxParticipants,
      };
      
      // Only include start_time and end_time if columns exist
      try {
        updateData.start_time = startDateTime.toISOString();
        updateData.end_time = endDateTime.toISOString();
      } catch {
        // Ignore if columns don't exist yet
      }
      
      const { error } = await supabase
        .from('sessions')
        .update(updateData)
        .eq('id', sessionId);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["sessions"] });
      setEditDialogOpen(false);
      toast.success("Session updated successfully!");
    },
    onError: (error) => {
      console.error('Error updating session:', error);
      toast.error(error instanceof Error ? error.message : "Failed to update session");
    },
  });
  
  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    updateSession.mutate();
  };
  
  // Cancel session mutation
  const cancelSession = useMutation({
    mutationFn: async () => {
      if (!sessionId || !user?.id || !selectedClub?.id) {
        throw new Error('Missing required data');
      }
      
      // First, delete all session registrations
      const { error: registrationError } = await supabase
        .from('session_registrations')
        .delete()
        .eq('session_id', sessionId);
      
      if (registrationError) {
        console.error('Error deleting registrations:', registrationError);
        throw new Error('Failed to remove registered users');
      }
      
      // Delete session payments if they exist
      const { error: paymentsError } = await supabase
        .from('session_payments')
        .delete()
        .eq('session_id', sessionId);
      
      // Don't throw on payments error as table might not exist or be empty
      if (paymentsError) {
        console.warn('Note: Could not delete payments (table may not exist):', paymentsError);
      }
      
      // Delete the session
      const { error: sessionError } = await supabase
        .from('sessions')
        .delete()
        .eq('id', sessionId);
      
      if (sessionError) {
        console.error('Error deleting session:', sessionError);
        throw new Error('Failed to delete session');
      }
      
      // Create activity record for the feed
      const { error: activityError } = await supabase
        .from('activities')
        .insert({
          club_id: selectedClub.id,
          type: 'session_cancelled',
          actor_id: user.id,
          target_id: sessionId,
          target_type: 'session',
          data: {
            session_date: session?.Date,
            session_venue: session?.Venue,
            registered_count: registeredUsers.length
          }
        });
      
      if (activityError) {
        console.error('Error creating activity record:', activityError);
        // Don't throw here as the main action succeeded
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["sessions"] });
      queryClient.invalidateQueries({ queryKey: ["club-activity"] });
      toast.success("Session cancelled successfully!");
      navigate('/schedule');
    },
    onError: (error) => {
      console.error('Error cancelling session:', error);
      toast.error(error instanceof Error ? error.message : "Failed to cancel session");
    },
  });
  
  const handleCancelSession = () => {
    if (!confirm(
      `Are you sure you want to cancel this session?\n\n` +
      `This will:\n` +
      `• Delete the session permanently\n` +
      `• Remove all ${registeredUsers.length} registered users\n` +
      `• Post an update to the club feed\n\n` +
      `This action cannot be undone.`
    )) {
      return;
    }
    
    cancelSession.mutate();
  };

  if (isLoadingSessions) {
    return (
      <div className="space-y-8">
        <div className="flex items-center gap-4">
          <Button variant="ghost" onClick={() => navigate('/schedule')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Schedule
          </Button>
        </div>
        <Card className="p-8 text-center bg-card border-border">
          <p className="text-muted-foreground">Loading session...</p>
        </Card>
      </div>
    );
  }

  if (!session) {
    return (
      <div className="space-y-8">
        <div className="flex items-center gap-4">
          <Button variant="ghost" onClick={() => navigate('/schedule')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Schedule
          </Button>
        </div>
        <Card className="p-8 text-center bg-card border-border">
          <p className="text-muted-foreground">Session not found</p>
        </Card>
      </div>
    );
  }

  const sessionDate = new Date(session.Date);
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Upcoming':
        return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      case 'Completed':
        return 'bg-green-500/10 text-green-500 border-green-500/20';
      case 'Cancelled':
        return 'bg-red-500/10 text-red-500 border-red-500/20';
      default:
        return 'bg-muted text-muted-foreground border-border';
    }
  };

  // Helper function to get participant display name
  const getParticipantName = (participant: any) => {
    if (participant.user_profiles?.first_name && participant.user_profiles?.last_name) {
      return `${participant.user_profiles.first_name} ${participant.user_profiles.last_name}`;
    }
    if (participant.user_profiles?.first_name) {
      return participant.user_profiles.first_name;
    }
    return 'Unknown User';
  };

  // Helper function to get participant initials
  const getParticipantInitials = (participant: any) => {
    if (participant.user_profiles?.first_name || participant.user_profiles?.last_name) {
      return `${participant.user_profiles.first_name?.[0] || ''}${participant.user_profiles.last_name?.[0] || ''}`.toUpperCase();
    }
    return 'U';
  };

  return (
    <div className="space-y-8">
      {/* Header with Back Button */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" onClick={() => navigate('/schedule')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Schedule
          </Button>
          <div>
            <h1 className="text-3xl font-bold text-foreground">
              Session Details
            </h1>
            <p className="text-muted-foreground mt-1">
              {format(sessionDate, 'EEEE, MMMM d, yyyy')}
            </p>
          </div>
        </div>
        <div className="flex gap-2">
          {session.Status === 'Upcoming' && user && !isAdmin && (
            <>
              {isUserRegistered ? (
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={handleUnregister}
                  disabled={unregisterMutation.isPending}
                >
                  <UserMinus className="h-4 w-4 mr-2" />
                  {unregisterMutation.isPending ? 'Removing...' : 'Unregister'}
                </Button>
              ) : (
                <Button 
                  size="sm"
                  variant={isSessionFull ? "outline" : "default"}
                  onClick={handleRegister}
                  disabled={registerMutation.isPending}
                >
                  <UserPlus className="h-4 w-4 mr-2" />
                  {registerMutation.isPending ? 'Registering...' : isSessionFull ? 'Join Waitlist' : 'Register'}
                </Button>
              )}
            </>
          )}
          {isAdmin && session.Status === 'Upcoming' && (
            <Button 
              variant="destructive" 
              size="sm"
              onClick={handleCancelSession}
              disabled={cancelSession.isPending}
            >
              <XCircle className="h-4 w-4 mr-2" />
              {cancelSession.isPending ? 'Cancelling...' : 'Cancel Session'}
            </Button>
          )}
          {isAdmin && (
            <Dialog open={editDialogOpen} onOpenChange={setEditDialogOpen}>
              <DialogTrigger asChild>
                <Button variant="outline" size="sm">
                  <Settings className="h-4 w-4 mr-2" />
                  Edit Session
                </Button>
              </DialogTrigger>
            <DialogContent className="sm:max-w-[425px] bg-card border-border">
              <DialogHeader>
                <DialogTitle className="text-card-foreground">Edit Session</DialogTitle>
              </DialogHeader>
              <form onSubmit={handleEditSubmit} className="space-y-4">
                <div>
                  <Label className="text-sm font-medium text-card-foreground">Date</Label>
                  <CalendarComponent
                    mode="single"
                    selected={editDate}
                    onSelect={setEditDate}
                    className="rounded-md border border-border bg-card w-full flex justify-center"
                  />
                </div>
                <div>
                  <Label className="text-sm font-medium text-card-foreground">Venue</Label>
                  <Select value={editVenue} onValueChange={setEditVenue}>
                    <SelectTrigger className="bg-background border-input">
                      <SelectValue placeholder="Select a venue" />
                    </SelectTrigger>
                    <SelectContent className="bg-popover border-border">
                      {getClubLocations().length > 0 ? (
                        getClubLocations().map((location, index) => (
                          <SelectItem key={index} value={location}>
                            {location}
                          </SelectItem>
                        ))
                      ) : (
                        <SelectItem value="no-location" disabled>
                          No locations configured for this club
                        </SelectItem>
                      )}
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label className="text-sm font-medium text-card-foreground">Start Time</Label>
                    <Input
                      type="time"
                      value={editStartTime}
                      onChange={(e) => setEditStartTime(e.target.value)}
                      className="bg-background border-input"
                    />
                  </div>
                  <div>
                    <Label className="text-sm font-medium text-card-foreground">End Time</Label>
                    <Input
                      type="time"
                      value={editEndTime}
                      onChange={(e) => setEditEndTime(e.target.value)}
                      className="bg-background border-input"
                    />
                  </div>
                </div>
                <div>
                  <Label className="text-sm font-medium text-card-foreground">Cost per Player (£)</Label>
                  <Input
                    type="number"
                    step="0.01"
                    min="0"
                    placeholder="0.00"
                    value={editCost}
                    onChange={(e) => setEditCost(e.target.value)}
                    className="bg-background border-input"
                  />
                </div>
                <div>
                  <Label className="text-sm font-medium text-card-foreground">Max Participants</Label>
                  <Input
                    type="number"
                    min="1"
                    max="50"
                    value={editMaxParticipants}
                    onChange={(e) => setEditMaxParticipants(parseInt(e.target.value) || 16)}
                    className="bg-background border-input"
                    placeholder="16"
                  />
                </div>
                <div className="flex justify-end space-x-2">
                  <Button type="button" variant="outline" onClick={() => setEditDialogOpen(false)}>
                    Cancel
                  </Button>
                  <Button 
                    type="submit" 
                    disabled={!editDate || !editVenue || editCost === "" || updateSession.isPending}
                  >
                    {updateSession.isPending ? 'Updating...' : 'Update Session'}
                  </Button>
                </div>
              </form>
            </DialogContent>
          </Dialog>
          )}
          {session.Status === 'Upcoming' && (
            <Button size="sm">
              <Play className="h-4 w-4 mr-2" />
              Start Session
            </Button>
          )}
        </div>
      </div>

      {/* Session Overview */}
      <Card className="bg-card border-border">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              Session Overview
            </CardTitle>
            <Badge className={cn("text-sm", getStatusColor(session.Status))}>
              {session.Status}
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <Calendar className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Date & Time</p>
                  <p className="font-medium text-card-foreground">
                    {format(sessionDate, 'MMM d, yyyy')}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {format(sessionDate, 'h:mm a')}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <MapPin className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Venue</p>
                  <p className="font-medium text-card-foreground">{session.Venue}</p>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <Users className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Participants</p>
                  <p className="font-medium text-card-foreground">
                    {registeredUsers.length}/{maxParticipants} registered
                  </p>
                  {waitlistUsers.length > 0 && (
                    <p className="text-sm text-muted-foreground">
                      {waitlistUsers.length} on waitlist
                    </p>
                  )}
                </div>
              </div>
              <div className="flex items-center gap-3">
                <Clock className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">
                    {session.registration_deadline ? 'Registration Deadline' : 'Duration'}
                  </p>
                  <p className="font-medium text-card-foreground">
                    {session.registration_deadline 
                      ? format(new Date(session.registration_deadline), 'MMM d, yyyy h:mm a')
                      : '2 hours'
                    }
                  </p>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <p className="text-sm text-muted-foreground">Session Fee</p>
                <p className="font-medium text-card-foreground">
                  {session.fee_per_player ? `£${Number(session.fee_per_player).toFixed(2)} per player` : 'Free'}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Registration Status</p>
                <p className="font-medium text-card-foreground">
                  {isUserRegistered 
                    ? userRegistration?.status === 'registered' 
                      ? 'You are registered' 
                      : 'You are on the waitlist'
                    : 'Not registered'
                  }
                </p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Participants */}
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            Participants ({(registrations || []).length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {isLoadingRegistrations ? (
            <div className="text-center py-8 text-muted-foreground">
              Loading participants...
            </div>
          ) : registrations && registrations.length > 0 ? (
            <div className="space-y-6">
              {/* Registered Players */}
              {registeredUsers.length > 0 && (
                <div>
                  <h4 className="text-sm font-medium text-muted-foreground mb-3">
                    Registered ({registeredUsers.length}/{maxParticipants})
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {registeredUsers.map((participant) => (
                      <div
                        key={participant.id}
                        className="flex items-center justify-between p-4 border border-border rounded-lg bg-accent/5"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center text-white text-sm font-bold">
                            {getParticipantInitials(participant)}
                          </div>
                          <div>
                            <p className="font-medium text-card-foreground">{getParticipantName(participant)}</p>
                            <p className="text-sm text-muted-foreground">
                              {participant.email || 'No email'}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              Level {participant.user_profiles?.skill_level || 'N/A'}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <CheckCircle className="h-4 w-4 text-green-500" />
                          <Badge variant="default" className="text-xs">
                            Registered
                          </Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Waitlist */}
              {waitlistUsers.length > 0 && (
                <div>
                  <h4 className="text-sm font-medium text-muted-foreground mb-3">
                    Waitlist ({waitlistUsers.length})
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {waitlistUsers.map((participant, index) => (
                      <div
                        key={participant.id}
                        className="flex items-center justify-between p-4 border border-border rounded-lg bg-accent/5"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-gradient-to-br from-yellow-500 to-orange-500 rounded-full flex items-center justify-center text-white text-sm font-bold">
                            {getParticipantInitials(participant)}
                          </div>
                          <div>
                            <p className="font-medium text-card-foreground">{getParticipantName(participant)}</p>
                            <p className="text-sm text-muted-foreground">
                              {participant.email || 'No email'}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              Level {participant.user_profiles?.skill_level || 'N/A'} • #{index + 1} in line
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <Clock className="h-4 w-4 text-yellow-500" />
                          <Badge variant="secondary" className="text-xs">
                            Waitlist
                          </Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Temporary Participants Section */}
              {session.Status === 'Upcoming' && (
                <div className="mt-8 pt-6 border-t border-border">
                  <TemporaryParticipantManager sessionId={sessionId || ''} />
                </div>
              )}
            </div>
          ) : (
            <div className="text-center py-8 space-y-4">
              <div className="text-muted-foreground">
                No participants registered yet.
              </div>
              {session.Status === 'Upcoming' && user && !isUserRegistered && (
                <Button onClick={handleRegister} disabled={registerMutation.isPending}>
                  <UserPlus className="h-4 w-4 mr-2" />
                  Be the first to register!
                </Button>
              )}
              
              {/* Temporary Participants Section - Show even when no registered users */}
              {session.Status === 'Upcoming' && (
                <div className="mt-8 pt-6 border-t border-border">
                  <TemporaryParticipantManager sessionId={sessionId || ''} />
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Court Schedule */}
      <Card className="bg-card border-border">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Play className="h-5 w-5" />
              Court Schedule
            </CardTitle>
            {scheduleData?.rotations && scheduleData.rotations.length > 0 && (
              <div className="flex items-center gap-2">
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={handleDeleteSchedule}
                  disabled={deleteScheduleMutation.isPending}
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  {deleteScheduleMutation.isPending ? 'Deleting...' : 'Delete Schedule'}
                </Button>
                <Button 
                  size="sm"
                  onClick={() => setScheduleDialogOpen(true)}
                  disabled={totalPlayers < 4}
                >
                  <Play className="h-4 w-4 mr-2" />
                  Regenerate Schedule
                </Button>
                <DownloadPdfButton
                  rotations={scheduleData.rotations}
                  sessionId={sessionId || ''}
                />
              </div>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {isLoadingSchedule ? (
            <div className="text-center py-8 text-muted-foreground">
              Loading court schedule...
            </div>
          ) : scheduleData?.rotations && scheduleData.rotations.length > 0 ? (
            <CourtDisplayWithScoring
              rotations={scheduleData.rotations}
              isKingCourt={false}
              sessionId={sessionId || ''}
              sessionStatus={session.Status}
            />
          ) : (
            <div className="text-center py-8 space-y-4">
              <div className="text-muted-foreground">
                No court schedule generated for this session yet.
              </div>
              <Button 
                onClick={() => setScheduleDialogOpen(true)}
                disabled={totalPlayers < 4}
              >
                <Play className="h-4 w-4 mr-2" />
                Generate Schedule
              </Button>
              {totalPlayers < 4 && (
                <p className="text-sm text-muted-foreground">
                  Need at least 4 players total (registered + temporary) to generate a schedule
                </p>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Schedule Generation Dialog */}
      <SessionScheduleDialog
        open={scheduleDialogOpen}
        onOpenChange={setScheduleDialogOpen}
        sessionId={sessionId || ''}
        registeredUsers={registrations || []}
        sessionStatus={session.Status}
      />
    </div>
  );
};

export default SessionDetail;