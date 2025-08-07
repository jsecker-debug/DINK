import { useState } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from "@/components/ui/dialog";
import { supabase } from "@/lib/supabase";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { format, isToday, isTomorrow, isYesterday } from "date-fns";
import { Calendar } from "@/components/ui/calendar";
import { cn } from "@/lib/utils";
import { 
  PlusIcon, 
  Calendar as CalendarIcon, 
  MapPin, 
  Users, 
  Clock,
  ChevronRight,
  Filter,
  Search,
  Banknote
} from "lucide-react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { useSessions } from "@/hooks/useSessions";
import { Session } from "@/hooks/useSessions";
import { useNavigate } from "react-router-dom";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/contexts/AuthContext";
import { useClub } from "@/contexts/ClubContext";
import { useSessionsParticipantCounts } from "@/hooks/useSessionParticipants";
import { useRegisterForSession } from "@/hooks/useSessionRegistration";

const Schedule = () => {
  const [date, setDate] = useState<Date>();
  const [venue, setVenue] = useState<string>();
  const [cost, setCost] = useState<string>("");
  const [startTime, setStartTime] = useState<string>("18:00");
  const [endTime, setEndTime] = useState<string>("20:00");
  const [maxParticipants, setMaxParticipants] = useState<number>(16);
  const [registrationDeadline, setRegistrationDeadline] = useState<Date>();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [venueFilter, setVenueFilter] = useState<string>("all");
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { selectedClub, selectedClubId } = useClub();
  
  const { data: sessions, isLoading, error } = useSessions();
  const registerForSession = useRegisterForSession();
  
  // Get participant counts for all sessions
  const sessionIds = sessions?.map(session => session.id) || [];
  const { data: participantCounts } = useSessionsParticipantCounts(sessionIds);

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

  const addSession = useMutation({
    mutationFn: async ({ date, venue, cost, startTime, endTime, maxParticipants, registrationDeadline }: { date: Date; venue: string; cost: number; startTime: string; endTime: string; maxParticipants: number; registrationDeadline?: Date }) => {
      // Capture club ID immediately to prevent race conditions
      const currentClubId = selectedClubId;
      const currentClub = selectedClub;
      
      if (!currentClubId) {
        throw new Error('No club selected');
      }
      
      // Validate that currentClubId is a valid UUID
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(currentClubId)) {
        console.error('Invalid club ID format:', currentClubId, 'type:', typeof currentClubId);
        console.error('Club object:', currentClub);
        console.error('All session IDs from hooks:', sessionIds);
        throw new Error(`Invalid club ID format: ${currentClubId}. Please refresh and select a club again.`);
      }
      
      console.log('Creating session with club_id:', currentClubId, 'type:', typeof currentClubId);
      console.log('Selected club:', currentClub);
      console.log('Session IDs in scope:', sessionIds);
      
      // Combine date with start and end times
      const startDateTime = new Date(date);
      const [startHour, startMinute] = startTime.split(':').map(Number);
      startDateTime.setHours(startHour, startMinute, 0, 0);
      
      const endDateTime = new Date(date);
      const [endHour, endMinute] = endTime.split(':').map(Number);
      endDateTime.setHours(endHour, endMinute, 0, 0);
      
      // If end time is before start time, assume it's the next day
      if (endDateTime <= startDateTime) {
        endDateTime.setDate(endDateTime.getDate() + 1);
      }
      
      // Create the session data object
      const sessionData = { 
        Date: startDateTime.toISOString(),
        Venue: venue,
        Status: 'Upcoming' as const,
        club_id: currentClubId,
        max_participants: maxParticipants,
        registration_deadline: registrationDeadline?.toISOString(),
        fee_per_player: cost,
        start_time: startDateTime.toISOString(),
        end_time: endDateTime.toISOString()
      };
      
      console.log('Session data being inserted:', sessionData);
      
      // Always set new sessions as Upcoming
      const { data, error } = await supabase
        .from("sessions")
        .insert([sessionData])
        .select();
      
      if (error) {
        console.error('Error adding session:', error);
        console.error('Failed session data:', sessionData);
        throw error;
      }
      
      // Update any existing activity record with the current user as the actor
      const createdSession = data?.[0];
      if (createdSession && currentClubId && user?.id) {
        // Wait a bit for the trigger to potentially create the activity
        await new Promise(resolve => setTimeout(resolve, 100));
        
        // Check if trigger already created an activity
        const { data: existingActivity } = await supabase
          .from('activities')
          .select('id')
          .eq('type', 'session_created')
          .eq('target_type', 'session')
          .eq('data->>session_id', createdSession.id.toString())
          .single();
        
        if (existingActivity) {
          // Update the existing activity with the real actor
          const { error: updateError } = await supabase
            .from('activities')
            .update({ actor_id: user.id })
            .eq('id', existingActivity.id);
          
          if (updateError) {
            console.error('Error updating activity record:', updateError);
          }
        } else {
          // Create new activity if none exists
          const { error: activityError } = await supabase
            .from('activities')
            .insert({
              club_id: currentClubId,
              type: 'session_created',
              actor_id: user.id,
              target_id: createdSession.id.toString(),
              target_type: 'session',
              data: {
                session_id: createdSession.id,
                session_date: createdSession.Date,
                venue: createdSession.Venue
              }
            });
          
          if (activityError) {
            console.error('Error creating activity record:', activityError);
          }
        }
      }
      
      return data;
    },
    onSuccess: (data) => {
      const createdSession = data?.[0];
      const clubIdForCache = createdSession?.club_id || selectedClubId;
      queryClient.invalidateQueries({ queryKey: ["sessions", clubIdForCache] });
      queryClient.invalidateQueries({ queryKey: ["club-activity", clubIdForCache] });
      setIsDialogOpen(false);
      setDate(undefined);
      setVenue(undefined);
      setCost("");
      setStartTime("18:00");
      setEndTime("20:00");
      setMaxParticipants(16);
      setRegistrationDeadline(undefined);
      toast.success("Session created successfully!");
    },
    onError: (error) => {
      console.error('Error creating session:', error);
      toast.error("Failed to create session");
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedClubId) {
      toast.error("Please select a club first");
      return;
    }
    if (!date || !venue || venue === 'no-location' || venue === 'no-club' || cost === "") {
      toast.error("Please fill in all required fields");
      return;
    }
    
    const costNumber = parseFloat(cost);
    if (isNaN(costNumber) || costNumber < 0) {
      toast.error("Please enter a valid cost (minimum £0.00)");
      return;
    }
    
    addSession.mutate({ date, venue, cost: costNumber, startTime, endTime, maxParticipants, registrationDeadline });
  };

  const getFilteredSessions = (): Session[] => {
    if (!sessions) return [];
    
    return sessions
      .filter(session => {
        // Search filter
        const matchesSearch = searchQuery === "" || 
          session.Venue.toLowerCase().includes(searchQuery.toLowerCase()) ||
          format(new Date(session.Date), 'PPP').toLowerCase().includes(searchQuery.toLowerCase());
        
        // Status filter
        const matchesStatus = statusFilter === "all" || session.Status === statusFilter;
        
        // Venue filter
        const matchesVenue = venueFilter === "all" || session.Venue === venueFilter;
        
        return matchesSearch && matchesStatus && matchesVenue;
      })
      .sort((a, b) => new Date(b.Date).getTime() - new Date(a.Date).getTime());
  };

  const getDateLabel = (date: Date): string => {
    if (isToday(date)) return "Today";
    if (isTomorrow(date)) return "Tomorrow";
    if (isYesterday(date)) return "Yesterday";
    return format(date, 'EEEE, MMM d');
  };

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

  const getUniqueVenues = (): string[] => {
    if (!sessions) return [];
    return Array.from(new Set(sessions.map(session => session.Venue)));
  };

  const SessionItem = ({ session }: { session: Session }) => {
    const sessionDate = new Date(session.Date);
    const participantCount = participantCounts?.[session.id] || 0;
    const maxParticipants = session.max_participants || 16;
    const isFull = participantCount >= maxParticipants;
    
    const handleCardClick = (e: React.MouseEvent) => {
      // Don't navigate if clicking on the register button
      if ((e.target as HTMLElement).closest('button')) {
        e.stopPropagation();
        return;
      }
      navigate(`/session/${session.id}`);
    };

    const handleRegisterClick = (e: React.MouseEvent) => {
      e.stopPropagation();
      if (!user) {
        toast.error("Please sign in to register for sessions");
        return;
      }
      
      // Register immediately
      registerForSession.mutate({ 
        sessionId: session.id, 
        session: {
          max_participants: session.max_participants,
          fee_per_player: session.fee_per_player
        }
      });
    };
    
    return (
      <Card 
        className="p-6 cursor-pointer hover:bg-accent/50 transition-all duration-200 border-border group"
        onClick={handleCardClick}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex-shrink-0">
              <div className="w-12 h-12 bg-gradient-to-br from-chart-1 to-chart-2 rounded-lg flex items-center justify-center">
                <CalendarIcon className="h-6 w-6 text-white" />
              </div>
            </div>
            
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <h3 className="text-lg font-semibold text-card-foreground">
                  {getDateLabel(sessionDate)}
                </h3>
                <Badge className={cn("text-xs", getStatusColor(session.Status))}>
                  {session.Status}
                </Badge>
              </div>
              
              <div className="flex items-center gap-4 text-sm text-muted-foreground">
                <div className="flex items-center gap-1">
                  <Clock className="h-4 w-4" />
                  <span>{format(sessionDate, 'h:mm a')}</span>
                </div>
                <div className="flex items-center gap-1">
                  <MapPin className="h-4 w-4" />
                  <span>{session.Venue}</span>
                </div>
                <div className="flex items-center gap-1">
                  <Users className="h-4 w-4" />
                  <span>
                    {participantCount}/{maxParticipants} players
                  </span>
                  {isFull && (
                    <span className="text-xs bg-red-500/10 text-red-500 px-1.5 py-0.5 rounded-full ml-1">
                      Full
                    </span>
                  )}
                </div>
                {session.fee_per_player && session.fee_per_player > 0 && (
                  <div className="flex items-center gap-1">
                    <Banknote className="h-4 w-4" />
                    <span>£{session.fee_per_player.toFixed(2)}</span>
                  </div>
                )}
              </div>
              
              <div className="mt-2 text-xs text-muted-foreground">
                {format(sessionDate, 'MMMM d, yyyy')}
              </div>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            {session.Status === 'Upcoming' && (
              <Button
                size="sm"
                variant={isFull ? "outline" : "default"}
                onClick={handleRegisterClick}
                disabled={registerForSession.isPending}
                className="min-w-[80px]"
              >
                {registerForSession.isPending ? "Registering..." : isFull ? "Join Waitlist" : "Register"}
              </Button>
            )}
            <ChevronRight className="h-5 w-5 text-muted-foreground group-hover:text-foreground transition-colors" />
          </div>
        </div>
      </Card>
    );
  };

  if (error) {
    return (
      <div className="space-y-8">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Schedule</h1>
          <p className="text-muted-foreground mt-2">Manage your pickleball sessions</p>
        </div>
        <Card className="p-8 text-center bg-card border-border">
          <p className="text-red-500">Error loading sessions. Please try again.</p>
        </Card>
      </div>
    );
  }

  const filteredSessions = getFilteredSessions();

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Schedule</h1>
          <p className="text-muted-foreground mt-2">
            Manage and view your pickleball sessions
          </p>
        </div>
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button className="flex items-center gap-2">
              <PlusIcon className="w-4 h-4" />
              New Session
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[425px] bg-card border-border">
            <DialogHeader>
              <DialogTitle className="text-card-foreground">Create New Session</DialogTitle>
              <DialogDescription className="text-muted-foreground">
                Schedule a new pickleball session for your club.
              </DialogDescription>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="text-sm font-medium text-card-foreground">Date</label>
                <Calendar
                  mode="single"
                  selected={date}
                  onSelect={setDate}
                  className="rounded-md border border-border bg-card w-full flex justify-center"
                  disabled={(date) => date < new Date()}
                />
              </div>
              <div>
                <label className="text-sm font-medium text-card-foreground">Venue</label>
                <Select value={venue} onValueChange={setVenue}>
                  <SelectTrigger className="bg-background border-input">
                    <SelectValue placeholder="Select a venue" />
                  </SelectTrigger>
                  <SelectContent className="bg-popover border-border">
                    {!selectedClub ? (
                      <SelectItem value="no-club" disabled>
                        Please select a club first
                      </SelectItem>
                    ) : getClubLocations().length > 0 ? (
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
                  <label className="text-sm font-medium text-card-foreground">Start Time</label>
                  <Input
                    type="time"
                    value={startTime}
                    onChange={(e) => setStartTime(e.target.value)}
                    className="bg-background border-input"
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-card-foreground">End Time</label>
                  <Input
                    type="time"
                    value={endTime}
                    onChange={(e) => setEndTime(e.target.value)}
                    className="bg-background border-input"
                  />
                </div>
              </div>
              <div>
                <label className="text-sm font-medium text-card-foreground">Cost per Player (£)</label>
                <Input
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={cost}
                  onChange={(e) => setCost(e.target.value)}
                  className="bg-background border-input"
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Fee that each player will pay for this session
                </p>
              </div>
              <div>
                <label className="text-sm font-medium text-card-foreground">Max Participants</label>
                <Input
                  type="number"
                  min="1"
                  max="50"
                  value={maxParticipants}
                  onChange={(e) => setMaxParticipants(parseInt(e.target.value) || 16)}
                  className="bg-background border-input"
                  placeholder="16"
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Maximum number of players allowed in this session
                </p>
              </div>
              <div>
                <label className="text-sm font-medium text-card-foreground">Registration Deadline (Optional)</label>
                <Calendar
                  mode="single"
                  selected={registrationDeadline}
                  onSelect={setRegistrationDeadline}
                  className="rounded-md border border-border bg-card w-full flex justify-center"
                  disabled={(dateToCheck) => {
                    const today = new Date();
                    today.setHours(0, 0, 0, 0);
                    
                    // Disable past dates
                    if (dateToCheck < today) return true;
                    
                    // If session date is selected, disable dates after session date
                    if (date) {
                      const sessionDate = new Date(date);
                      sessionDate.setHours(0, 0, 0, 0);
                      return dateToCheck > sessionDate;
                    }
                    
                    return false;
                  }}
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Players can register until this date. Leave empty for no deadline.
                </p>
              </div>
              <div className="flex justify-end space-x-2">
                <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={!date || !venue || venue === 'no-location' || venue === 'no-club' || cost === "" || addSession.isPending}>
                  {addSession.isPending ? 'Creating...' : 'Create Session'}
                </Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {/* Filters and Search */}
      <Card className="p-6 bg-card border-border">
        <div className="flex flex-col space-y-4 md:flex-row md:space-y-0 md:space-x-4">
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search sessions by date or venue..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 bg-background border-border"
              />
            </div>
          </div>
          
          <div className="flex gap-2">
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-[140px] bg-background border-border">
                <Filter className="h-4 w-4 mr-2" />
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-popover border-border">
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="Upcoming">Upcoming</SelectItem>
                <SelectItem value="Completed">Completed</SelectItem>
                <SelectItem value="Cancelled">Cancelled</SelectItem>
              </SelectContent>
            </Select>

            <Select value={venueFilter} onValueChange={setVenueFilter}>
              <SelectTrigger className="w-[180px] bg-background border-border">
                <MapPin className="h-4 w-4 mr-2" />
                <SelectValue placeholder="All Venues" />
              </SelectTrigger>
              <SelectContent className="bg-popover border-border">
                <SelectItem value="all">All Venues</SelectItem>
                {getUniqueVenues().map((venue) => (
                  <SelectItem key={venue} value={venue}>
                    {venue}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>
      </Card>

      {/* Sessions List */}
      {isLoading ? (
        <Card className="p-8 text-center bg-card border-border">
          <div className="text-muted-foreground">Loading sessions...</div>
        </Card>
      ) : filteredSessions.length > 0 ? (
        <div className="space-y-4">
          {filteredSessions.map((session) => (
            <SessionItem key={session.id} session={session} />
          ))}
        </div>
      ) : (
        <Card className="p-8 text-center bg-card border-border">
          <div className="space-y-2">
            <p className="text-muted-foreground">No sessions found.</p>
            {(searchQuery || statusFilter !== "all" || venueFilter !== "all") && (
              <p className="text-sm text-muted-foreground">
                Try adjusting your search or filters.
              </p>
            )}
          </div>
        </Card>
      )}
    </div>
  );
};

export default Schedule;