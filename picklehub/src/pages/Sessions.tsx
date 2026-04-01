import { useState } from "react";
import React from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { supabase } from "@/lib/supabase";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { format } from "date-fns";
import { Calendar } from "@/components/ui/calendar";
import { cn } from "@/lib/utils";
import { PlusIcon, Download } from "lucide-react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { useSessions } from "@/hooks/useSessions";
import { useSessionSchedule } from "@/hooks/useSessionSchedule";
import { Session } from "@/hooks/useSessions";
import CourtDisplay from "@/components/CourtDisplay";
import DownloadPdfButton from "@/components/DownloadPdfButton";
import { useClub } from "@/contexts/ClubContext";
import { useAuth } from "@/contexts/AuthContext";

const Sessions = () => {
  const [date, setDate] = useState<Date>();
  const [venue, setVenue] = useState<string>();
  const [cost, setCost] = useState<string>("");
  const [startTime, setStartTime] = useState<string>("18:00");
  const [endTime, setEndTime] = useState<string>("20:00");
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [selectedSessionId, setSelectedSessionId] = useState<string | null>(null);
  const queryClient = useQueryClient();
  const { selectedClubId } = useClub();
  const { user } = useAuth();
  
  const { data: sessions, isLoading, error } = useSessions();
  const { data: scheduleData, isLoading: isLoadingSchedule } = useSessionSchedule(selectedSessionId);

  // Check if user is admin
  const [isAdmin, setIsAdmin] = useState(false);
  
  // Check admin status
  React.useEffect(() => {
    const checkAdminStatus = async () => {
      if (!user || !selectedClubId) return;
      
      const { data } = await supabase
        .from('club_memberships')
        .select('role')
        .eq('user_id', user.id)
        .eq('club_id', selectedClubId)
        .single();
      
      setIsAdmin(data?.role === 'admin');
    };
    
    checkAdminStatus();
  }, [user, selectedClubId]);

  const addSession = useMutation({
    mutationFn: async ({ date, venue, cost, startTime, endTime }: { date: Date; venue: string; cost: number; startTime: string; endTime: string }) => {
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
      
      // Always set new sessions as Upcoming
      const { data, error } = await supabase
        .from("sessions")
        .insert([{ 
          Date: startDateTime.toISOString(),
          Venue: venue,
          Status: 'Upcoming',
          fee_per_player: cost,
          club_id: selectedClubId,
          start_time: startDateTime.toISOString(),
          end_time: endDateTime.toISOString()
        }])
        .select();
      
      if (error) {
        console.error('Error adding session:', error);
        throw error;
      }
      
      // Update any existing activity record with the current user as the actor
      const createdSession = data?.[0];
      if (createdSession && selectedClubId && user?.id) {
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
              club_id: selectedClubId,
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
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["sessions"] });
      queryClient.invalidateQueries({ queryKey: ["club-activity", selectedClubId] });
      setIsDialogOpen(false);
      setDate(undefined);
      setVenue(undefined);
      setCost("");
      setStartTime("18:00");
      setEndTime("20:00");
      toast.success("Session added successfully");
    },
    onError: (error) => {
      toast.error("Failed to add session");
      console.error("Error adding session:", error);
    },
  });

  const handleSubmit = () => {
    if (!date || !venue || cost === "") {
      toast.error("Please fill in all fields");
      return;
    }
    
    const costNumber = parseFloat(cost);
    if (isNaN(costNumber) || costNumber < 0) {
      toast.error("Please enter a valid cost (minimum £0.00)");
      return;
    }
    
    addSession.mutate({ date, venue, cost: costNumber, startTime, endTime });
  };

  const getNextSession = (sessions: Session[]) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    return sessions
      .filter(session => {
        const sessionDate = new Date(session.Date);
        sessionDate.setHours(0, 0, 0, 0);
        return sessionDate >= today;
      })
      .sort((a, b) => new Date(a.Date).getTime() - new Date(b.Date).getTime())[0];
  };

  const getUpcomingSessions = (sessions: Session[]) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const nextSession = getNextSession(sessions);
    
    return sessions
      .filter(session => {
        const sessionDate = new Date(session.Date);
        sessionDate.setHours(0, 0, 0, 0);
        return sessionDate >= today && (!nextSession || session.id !== nextSession.id);
      })
      .sort((a, b) => new Date(a.Date).getTime() - new Date(b.Date).getTime());
  };

  const getCompletedSessions = (sessions: Session[]) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    return sessions
      .filter(session => {
        const sessionDate = new Date(session.Date);
        sessionDate.setHours(0, 0, 0, 0);
        return sessionDate < today;
      })
      .sort((a, b) => new Date(b.Date).getTime() - new Date(a.Date).getTime());
  };

  const SessionCard = ({ title, sessions }: { title: string; sessions: Session[] | undefined }) => (
    <Card className="p-6 mb-6 bg-card border-border">
      <h2 className="text-xl font-semibold mb-4 text-card-foreground">{title}</h2>
      {sessions && sessions.length > 0 ? (
        <div className="space-y-4">
          {sessions.map((session) => (
            <div 
              key={session.id} 
              className="flex justify-between items-center p-4 border border-border rounded-lg cursor-pointer hover:bg-accent hover:text-accent-foreground transition-colors"
              onClick={() => setSelectedSessionId(session.id)}
            >
              <div>
                <p className="font-medium">{format(new Date(session.Date), 'PPP')}</p>
                <p className="text-muted-foreground">{session.Venue}</p>
              </div>
              <span className={cn(
                "px-3 py-1 rounded-full text-sm font-medium",
                session.Status === 'Upcoming' 
                  ? 'bg-chart-1/10 text-chart-1 border border-chart-1/20' 
                  : 'bg-muted text-muted-foreground border border-border'
              )}>
                {session.Status}
              </span>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center text-muted-foreground">
          No {title.toLowerCase()} sessions found.
        </div>
      )}
    </Card>
  );

  if (error) {
    return <div className="container mx-auto p-6">Error loading sessions</div>;
  }

  return (
    <div className="h-full">
      <div className="max-w-full mx-auto">
        <div className="mb-8 flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-foreground font-anybody">Sessions</h1>
            <p className="text-muted-foreground mt-2">Manage your pickleball sessions</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button disabled={!isAdmin} title={!isAdmin ? "Admin privileges required to create sessions" : "Create a new session"}>
                <PlusIcon className="mr-2 h-4 w-4" />
                Add Session {!isAdmin && "(Admin Only)"}
              </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px]">
              <DialogHeader>
                <DialogTitle>Add New Session</DialogTitle>
                <DialogDescription>
                  Select a date, venue and cost for the new session.
                </DialogDescription>
              </DialogHeader>
              <div className="grid gap-4 py-4">
                <div className="space-y-2">
                  <Label className="text-sm font-medium">Date</Label>
                  <div className="flex justify-center">
                    <Calendar
                      mode="single"
                      selected={date}
                      onSelect={setDate}
                      initialFocus
                      className="rounded-md border"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label className="text-sm font-medium">Venue</Label>
                  <Select onValueChange={setVenue} value={venue}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select venue" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Eton">Eton</SelectItem>
                      <SelectItem value="Windsor">Windsor</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">Start Time</Label>
                    <Input
                      type="time"
                      value={startTime}
                      onChange={(e) => setStartTime(e.target.value)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">End Time</Label>
                    <Input
                      type="time"
                      value={endTime}
                      onChange={(e) => setEndTime(e.target.value)}
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="cost" className="text-sm font-medium">Cost per Player (£)</Label>
                  <Input
                    id="cost"
                    type="number"
                    step="0.01"
                    min="0"
                    placeholder="0.00"
                    value={cost}
                    onChange={(e) => setCost(e.target.value)}
                  />
                </div>
              </div>
              <div className="flex justify-end space-x-2">
                <Button 
                  variant="outline" 
                  onClick={() => setIsDialogOpen(false)}
                >
                  Cancel
                </Button>
                <Button 
                  onClick={handleSubmit}
                  disabled={!date || !venue || cost === ""}
                >
                  Create Session
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        </div>

        {isLoading ? (
          <div className="text-center text-gray-500">Loading sessions...</div>
        ) : sessions ? (
          <>
            <SessionCard 
              title="Next Session" 
              sessions={getNextSession(sessions) ? [getNextSession(sessions)!] : []} 
            />
            <SessionCard 
              title="Upcoming Sessions" 
              sessions={getUpcomingSessions(sessions)} 
            />
            <SessionCard 
              title="Completed Sessions" 
              sessions={getCompletedSessions(sessions)} 
            />

            {selectedSessionId && (
              <Dialog open={!!selectedSessionId} onOpenChange={(open) => !open && setSelectedSessionId(null)}>
                <DialogContent className="max-w-4xl max-h-[calc(100vh-24px)] my-12 overflow-y-auto">
                  <DialogHeader>
                    <DialogTitle className="text-3xl font-bold text-primary">Session Schedule</DialogTitle>
                    <DialogDescription>
                      View and manage the schedule for this session.
                    </DialogDescription>
                  </DialogHeader>
                  {isLoadingSchedule ? (
                    <div className="text-center py-4">Loading schedule...</div>
                  ) : scheduleData ? (
                    <div className="space-y-6 pt-4">
                      {(scheduleData.randomRotations.length > 0 || scheduleData.kingCourtRotation) ? (
                        <>
                          <DownloadPdfButton 
                            contentId="session-schedule"
                            fileName="session-schedule"
                            className="w-full p-6 text-lg flex items-center justify-center gap-2 bg-primary hover:bg-primary/90"
                          >
                            <Download className="w-6 h-6" />
                            Download Session Schedule
                          </DownloadPdfButton>
                          <div id="session-schedule">
                            {scheduleData.randomRotations.length > 0 && (
                              <CourtDisplay 
                                rotations={scheduleData.randomRotations} 
                                isKingCourt={false}
                                sessionId={selectedSessionId}
                                sessionStatus={sessions?.find(s => s.id === selectedSessionId)?.Status}
                              />
                            )}
                            {scheduleData.kingCourtRotation && (
                              <CourtDisplay 
                                rotations={[scheduleData.kingCourtRotation]} 
                                isKingCourt={true}
                                sessionId={selectedSessionId}
                                sessionStatus={sessions?.find(s => s.id === selectedSessionId)?.Status}
                              />
                            )}
                          </div>
                        </>
                      ) : (
                        <div className="text-center py-4 text-gray-500">
                          No Session Generated
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="text-center py-4 text-gray-500">
                      No schedule found for this session.
                    </div>
                  )}
                </DialogContent>
              </Dialog>
            )}
          </>
        ) : null}
      </div>
    </div>
  );
};

export default Sessions;
