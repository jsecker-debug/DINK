import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Checkbox } from "@/components/ui/checkbox";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { supabase } from "@/lib/supabase";
import { useClub } from "@/contexts/ClubContext";
import { useAuth } from "@/contexts/AuthContext";
import { toast } from "sonner";
import { format } from "date-fns";
import { 
  DollarSign, 
  Calendar,
  Users,
  CheckCircle,
  Clock,
  AlertCircle
} from "lucide-react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

interface Session {
  id: number;
  Date: string;
  Venue: string;
  fee_per_player: number;
}

interface SessionRegistration {
  id: string;
  user_id: string;
  status: string;
  fee_amount: number;
  user_profiles: {
    first_name: string;
    last_name: string;
    email: string;
  };
}

interface PaymentStatus {
  registration_id: string;
  paid: boolean;
}

const Payments = () => {
  const [selectedSessionId, setSelectedSessionId] = useState<string>("");
  const [paymentStatuses, setPaymentStatuses] = useState<Record<string, boolean>>({});
  const { selectedClubId } = useClub();
  const { user } = useAuth();
  const queryClient = useQueryClient();

  // Check if user is admin
  const [isAdmin, setIsAdmin] = useState(false);
  
  useEffect(() => {
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

  // Fetch sessions with fees
  const { data: sessions = [] } = useQuery({
    queryKey: ['sessions-with-fees', selectedClubId],
    queryFn: async () => {
      if (!selectedClubId) return [];
      
      const { data, error } = await supabase
        .from('sessions')
        .select('id, Date, Venue, fee_per_player')
        .eq('club_id', selectedClubId)
        .gt('fee_per_player', 0)
        .order('Date', { ascending: false });
      
      if (error) throw error;
      return data as Session[];
    },
    enabled: !!selectedClubId && isAdmin
  });

  // Fetch registrations for selected session
  const { data: registrations = [] } = useQuery({
    queryKey: ['session-registrations', selectedSessionId],
    queryFn: async () => {
      if (!selectedSessionId) return [];
      
      const { data, error } = await supabase
        .from('session_registrations')
        .select(`
          id,
          user_id,
          status,
          fee_amount,
          user_profiles!inner (
            first_name,
            last_name,
            email
          )
        `)
        .eq('session_id', selectedSessionId)
        .eq('status', 'registered');
      
      if (error) throw error;
      return data as SessionRegistration[];
    },
    enabled: !!selectedSessionId && isAdmin
  });

  // Fetch current payment statuses
  const { data: currentPaymentStatuses = [] } = useQuery({
    queryKey: ['payment-statuses', selectedSessionId],
    queryFn: async () => {
      if (!selectedSessionId) return [];
      
      const { data, error } = await supabase
        .from('session_payments')
        .select('registration_id, paid')
        .eq('session_id', selectedSessionId);
      
      if (error) throw error;
      return data as PaymentStatus[];
    },
    enabled: !!selectedSessionId && isAdmin
  });

  // Initialize payment statuses when data loads
  useEffect(() => {
    const statusMap: Record<string, boolean> = {};
    registrations.forEach(reg => {
      const existingStatus = currentPaymentStatuses.find(ps => ps.registration_id === reg.id);
      statusMap[reg.id] = existingStatus?.paid ?? false;
    });
    setPaymentStatuses(statusMap);
  }, [registrations, currentPaymentStatuses]);

  // Update payment status mutation
  const updatePaymentStatus = useMutation({
    mutationFn: async ({ registrationId, paid }: { registrationId: string; paid: boolean }) => {
      const { error } = await supabase
        .from('session_payments')
        .upsert({
          session_id: selectedSessionId,
          registration_id: registrationId,
          paid: paid,
          updated_at: new Date().toISOString()
        }, {
          onConflict: 'session_id,registration_id'
        });
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['payment-statuses', selectedSessionId] });
      toast.success('Payment status updated');
    },
    onError: () => {
      toast.error('Failed to update payment status');
    }
  });

  const handlePaymentToggle = (registrationId: string, paid: boolean) => {
    setPaymentStatuses(prev => ({
      ...prev,
      [registrationId]: paid
    }));
    updatePaymentStatus.mutate({ registrationId, paid });
  };

  const selectedSession = sessions.find(s => s.id.toString() === selectedSessionId);
  const totalPlayers = registrations.length;
  const expectedTotal = selectedSession ? selectedSession.fee_per_player * totalPlayers : 0;
  const paidCount = Object.values(paymentStatuses).filter(Boolean).length;
  const unpaidCount = totalPlayers - paidCount;
  const collectedAmount = selectedSession ? selectedSession.fee_per_player * paidCount : 0;

  if (!isAdmin) {
    return (
      <div className="h-full flex items-center justify-center">
        <Card className="p-8">
          <div className="text-center">
            <AlertCircle className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h2 className="text-xl font-semibold mb-2">Admin Access Required</h2>
            <p className="text-muted-foreground">You need admin privileges to access payment tracking.</p>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-foreground">Payment Tracking</h1>
        <p className="text-muted-foreground mt-2">
          Track session payments and manage member payment status
        </p>
      </div>

      {/* Session Selector */}
      <Card>
        <CardHeader>
          <CardTitle>Select Session</CardTitle>
        </CardHeader>
        <CardContent>
          <Select value={selectedSessionId} onValueChange={setSelectedSessionId}>
            <SelectTrigger className="w-full">
              <SelectValue placeholder="Choose a session with fees to track payments" />
            </SelectTrigger>
            <SelectContent>
              {sessions.map((session) => (
                <SelectItem key={session.id} value={session.id.toString()}>
                  {format(new Date(session.Date), 'PPP')} - {session.Venue} (£{session.fee_per_player.toFixed(2)})
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </CardContent>
      </Card>

      {selectedSession && (
        <>
          {/* Payment Summary */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <Card>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Total Players</p>
                    <p className="text-2xl font-bold text-card-foreground">{totalPlayers}</p>
                  </div>
                  <Users className="h-8 w-8 text-chart-1" />
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Expected Total</p>
                    <p className="text-2xl font-bold text-card-foreground">£{expectedTotal.toFixed(2)}</p>
                  </div>
                  <DollarSign className="h-8 w-8 text-chart-2" />
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Collected</p>
                    <p className="text-2xl font-bold text-green-500">£{collectedAmount.toFixed(2)}</p>
                  </div>
                  <CheckCircle className="h-8 w-8 text-green-500" />
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Outstanding</p>
                    <p className="text-2xl font-bold text-red-500">£{(expectedTotal - collectedAmount).toFixed(2)}</p>
                  </div>
                  <Clock className="h-8 w-8 text-red-500" />
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Session Details */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calendar className="h-5 w-5" />
                Session Details
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <p className="text-sm text-muted-foreground">Date</p>
                  <p className="font-medium">{format(new Date(selectedSession.Date), 'PPP')}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Venue</p>
                  <p className="font-medium">{selectedSession.Venue}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Fee per Player</p>
                  <p className="font-medium">£{selectedSession.fee_per_player.toFixed(2)}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Payment Tracking */}
          <Card>
            <CardHeader>
              <CardTitle>Player Payments</CardTitle>
            </CardHeader>
            <CardContent>
              {registrations.length > 0 ? (
                <div className="space-y-3">
                  {registrations.map((registration) => (
                    <div 
                      key={registration.id}
                      className="flex items-center justify-between p-4 border border-border rounded-lg"
                    >
                      <div className="flex items-center space-x-4">
                        <Checkbox
                          checked={paymentStatuses[registration.id] || false}
                          onCheckedChange={(checked) => 
                            handlePaymentToggle(registration.id, checked as boolean)
                          }
                        />
                        <div>
                          <p className="font-medium">
                            {registration.user_profiles.first_name} {registration.user_profiles.last_name}
                          </p>
                          <p className="text-sm text-muted-foreground">
                            {registration.user_profiles.email}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-4">
                        <span className="font-medium">
                          £{registration.fee_amount?.toFixed(2) || selectedSession.fee_per_player.toFixed(2)}
                        </span>
                        <Badge 
                          variant={paymentStatuses[registration.id] ? "default" : "secondary"}
                          className={paymentStatuses[registration.id] 
                            ? "bg-green-500/10 text-green-500 border-green-500/20" 
                            : "bg-yellow-500/10 text-yellow-500 border-yellow-500/20"
                          }
                        >
                          {paymentStatuses[registration.id] ? (
                            <>
                              <CheckCircle className="h-3 w-3 mr-1" />
                              Paid
                            </>
                          ) : (
                            <>
                              <Clock className="h-3 w-3 mr-1" />
                              Pending
                            </>
                          )}
                        </Badge>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center text-muted-foreground py-8">
                  No registered players found for this session.
                </div>
              )}
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
};

export default Payments;