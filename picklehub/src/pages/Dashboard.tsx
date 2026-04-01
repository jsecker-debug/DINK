import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Link } from "react-router-dom";
import { 
  Calendar, 
  Users, 
  Trophy, 
  Clock,
  ArrowRight,
  TrendingUp,
  Activity,
  DollarSign,
  AlertCircle
} from "lucide-react";
import { useSessions } from "@/hooks/useSessions";
import { useParticipants } from "@/hooks/useParticipants";
import { useClub } from "@/contexts/ClubContext";
import { useAuth } from "@/contexts/AuthContext";
import { useQueryClient } from "@tanstack/react-query";
import { format } from "date-fns";

const Dashboard = () => {
  const { data: sessions } = useSessions();
  const { data: participants, isLoading: participantsLoading, error: participantsError } = useParticipants();
  const { selectedClub, selectedClubId } = useClub();
  const { user } = useAuth();
  const queryClient = useQueryClient();

  // Calculate some basic stats
  const upcomingSessions = sessions?.filter(session => {
    const sessionDate = new Date(session.Date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    sessionDate.setHours(0, 0, 0, 0);
    return sessionDate >= today;
  }) || [];

  const recentSessions = sessions?.filter(session => {
    const sessionDate = new Date(session.Date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    sessionDate.setHours(0, 0, 0, 0);
    return sessionDate < today;
  }).slice(0, 3) || [];

  const totalMembers = participants?.length || 0;
  const activePlayers = participants?.filter(p => p.total_games_played > 0).length || 0;

  // Mock payment data - in real app this would come from backend
  const outstandingBalance = 45.00;
  const hasOutstandingPayments = outstandingBalance > 0;

  return (
    <div className="space-y-8">

      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-foreground">Dashboard</h1>
        <p className="text-muted-foreground mt-2">
          {selectedClub ? `Welcome to ${selectedClub.name}` : 'Welcome to your pickleball club management hub'}
        </p>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Total Members</p>
              <p className="text-2xl font-bold text-card-foreground">{totalMembers}</p>
            </div>
            <Users className="h-8 w-8 text-chart-1" />
          </div>
        </Card>
        
        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Active Players</p>
              <p className="text-2xl font-bold text-card-foreground">{activePlayers}</p>
            </div>
            <Activity className="h-8 w-8 text-chart-2" />
          </div>
        </Card>
        
        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Upcoming Sessions</p>
              <p className="text-2xl font-bold text-card-foreground">{upcomingSessions.length}</p>
            </div>
            <Calendar className="h-8 w-8 text-chart-3" />
          </div>
        </Card>
        
        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Total Sessions</p>
              <p className="text-2xl font-bold text-card-foreground">{sessions?.length || 0}</p>
            </div>
            <Trophy className="h-8 w-8 text-chart-4" />
          </div>
        </Card>

        <Card className={`p-6 border ${hasOutstandingPayments ? 'bg-red-500/5 border-red-500/20' : 'bg-card border-border'}`}>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Amount Due</p>
              <p className={`text-2xl font-bold ${hasOutstandingPayments ? 'text-red-500' : 'text-green-500'}`}>
                ${outstandingBalance.toFixed(2)}
              </p>
            </div>
            {hasOutstandingPayments ? (
              <AlertCircle className="h-8 w-8 text-red-500" />
            ) : (
              <DollarSign className="h-8 w-8 text-green-500" />
            )}
          </div>
          {hasOutstandingPayments && (
            <div className="mt-3">
              <Link to="/payments">
                <Button size="sm" variant="destructive" className="w-full">
                  Pay Now
                </Button>
              </Link>
            </div>
          )}
        </Card>
      </div>

      {/* Quick Actions */}
      <Card className="p-6 bg-card border-border">
        <h2 className="text-xl font-semibold text-card-foreground mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
          <Link to="/schedule">
            <Button className="w-full h-12 justify-start" variant="outline">
              <Calendar className="mr-2 h-4 w-4" />
              Schedule Session
            </Button>
          </Link>
          <Link to="/members">
            <Button className="w-full h-12 justify-start" variant="outline">
              <Users className="mr-2 h-4 w-4" />
              Manage Members
            </Button>
          </Link>
          <Link to="/scheduler">
            <Button className="w-full h-12 justify-start" variant="outline">
              <Activity className="mr-2 h-4 w-4" />
              Generate Games
            </Button>
          </Link>
          <Link to="/rankings">
            <Button className="w-full h-12 justify-start" variant="outline">
              <Trophy className="mr-2 h-4 w-4" />
              View Rankings
            </Button>
          </Link>
          <Link to="/payments">
            <Button className="w-full h-12 justify-start" variant="outline">
              <DollarSign className="mr-2 h-4 w-4" />
              Manage Payments
            </Button>
          </Link>
        </div>
      </Card>

      {/* Upcoming Sessions */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-card-foreground">Upcoming Sessions</h2>
            <Link to="/schedule">
              <Button variant="ghost" size="sm">
                View All <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>
          {upcomingSessions.length > 0 ? (
            <div className="space-y-3">
              {upcomingSessions.slice(0, 3).map((session) => (
                <div key={session.id} className="flex items-center justify-between p-3 rounded-lg border border-border bg-accent/5">
                  <div>
                    <p className="font-medium text-card-foreground">
                      {format(new Date(session.Date), 'PPP')}
                    </p>
                    <p className="text-sm text-muted-foreground">{session.Venue}</p>
                  </div>
                  <Badge variant="secondary" className="bg-chart-1/10 text-chart-1">
                    {session.Status}
                  </Badge>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center text-muted-foreground py-4">
              No upcoming sessions scheduled
            </div>
          )}
        </Card>

        {/* Recent Activity */}
        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-card-foreground">Recent Sessions</h2>
            <Link to="/schedule">
              <Button variant="ghost" size="sm">
                View All <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>
          {recentSessions.length > 0 ? (
            <div className="space-y-3">
              {recentSessions.map((session) => (
                <div key={session.id} className="flex items-center justify-between p-3 rounded-lg border border-border bg-accent/5">
                  <div>
                    <p className="font-medium text-card-foreground">
                      {format(new Date(session.Date), 'PPP')}
                    </p>
                    <p className="text-sm text-muted-foreground">{session.Venue}</p>
                  </div>
                  <Badge variant="outline" className="text-muted-foreground">
                    Completed
                  </Badge>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center text-muted-foreground py-4">
              No recent sessions found
            </div>
          )}
        </Card>
      </div>

      {/* Getting Started */}
      <Card className="p-8 bg-card border-border">
        <div className="flex items-start gap-4">
          <TrendingUp className="h-8 w-8 text-primary flex-shrink-0 mt-1" />
          <div>
            <h2 className="text-xl font-semibold text-card-foreground mb-2">
              Get Started with DINK
            </h2>
            <p className="text-muted-foreground mb-4">
              Set up your pickleball club and start managing sessions, members, and rankings.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link to="/members">
                <Button>Add Your First Members</Button>
              </Link>
              <Link to="/schedule">
                <Button variant="outline">Schedule a Session</Button>
              </Link>
            </div>
          </div>
        </div>
      </Card>
    </div>
  );
};

export default Dashboard;