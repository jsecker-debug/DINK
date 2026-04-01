import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from "@/components/ui/dialog";
import { useClubMembers, type ClubMember } from "@/hooks/useClubMembers";
import { useParticipants } from "@/hooks/useParticipants";
import { useClub } from "@/contexts/ClubContext";
import { useAuth } from "@/contexts/AuthContext";
import { AddParticipantDialog } from "@/components/AddParticipantDialog";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";
import { format } from "date-fns";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Search,
  UserPlus,
  Users,
  Trophy,
  Activity,
  Crown,
  Medal,
  Award,
  TrendingUp,
  TrendingDown,
  Minus,
  Star,
  BarChart3,
  AlertTriangle,
  Settings,
  MapPin,
  DollarSign,
  Calendar,
  CheckCircle,
  Clock,
  AlertCircle,
} from "lucide-react";

type SortOption = "level" | "winrate" | "games" | "wins" | "confidence";
type FilterOption = "all" | "active" | "male" | "female" | "low-confidence";

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

const Club = () => {
  const navigate = useNavigate();
  const { selectedClub, selectedClubId } = useClub();
  const { user } = useAuth();
  const queryClient = useQueryClient();

  // ---- Admin check ----
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    if (selectedClub?.role === "admin") {
      setIsAdmin(true);
      return;
    }
    const checkAdminStatus = async () => {
      if (!user || !selectedClubId) return;
      const { data } = await supabase
        .from("club_memberships")
        .select("role")
        .eq("user_id", user.id)
        .eq("club_id", selectedClubId)
        .single();
      setIsAdmin(data?.role === "admin");
    };
    checkAdminStatus();
  }, [user, selectedClubId, selectedClub]);

  // ---- Members tab state ----
  const [searchInput, setSearchInput] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const { data: members, isLoading: membersLoading, error: membersError } = useClubMembers();

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setSearchQuery(searchInput);
  };
  const handleClearSearch = () => {
    setSearchInput("");
    setSearchQuery("");
  };

  const totalMembers = members?.length || 0;
  const activeMembers = members?.filter((m) => (m.total_games_played || 0) > 0).length || 0;
  const newMembers = members?.filter((m) => (m.total_games_played || 0) === 0).length || 0;
  const averageLevel = members?.length
    ? (members.reduce((sum, m) => sum + (m.level || 0), 0) / members.length).toFixed(1)
    : "0.0";

  const filteredMembers =
    members?.filter((member) => {
      if (!searchQuery) return true;
      const fullName = member.user_metadata?.full_name || "";
      const email = member.user_metadata?.email || "";
      return (
        fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        email.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }) || [];

  // ---- Rankings tab state ----
  const { data: participants, isLoading: rankingsLoading, error: rankingsError } = useParticipants();
  const [sortBy, setSortBy] = useState<SortOption>("level");
  const [filterBy, setFilterBy] = useState<FilterOption>("all");

  const processedParticipants =
    participants
      ?.filter((participant) => {
        switch (filterBy) {
          case "active":
            return participant.total_games_played > 0;
          case "male":
            return participant.gender === "M";
          case "female":
            return participant.gender === "F";
          case "low-confidence":
            return (participant.rating_confidence || 0) < 0.2;
          default:
            return true;
        }
      })
      ?.map((participant) => ({
        ...participant,
        winRate: participant.total_games_played > 0 ? (participant.wins / participant.total_games_played) * 100 : 0,
      }))
      ?.sort((a, b) => {
        switch (sortBy) {
          case "level":
            return (b.skill_level || 0) - (a.skill_level || 0);
          case "winrate":
            return b.winRate - a.winRate;
          case "games":
            return b.total_games_played - a.total_games_played;
          case "wins":
            return b.wins - a.wins;
          case "confidence":
            return (b.rating_confidence || 0) - (a.rating_confidence || 0);
          default:
            return 0;
        }
      }) || [];

  const getRankIcon = (index: number) => {
    switch (index) {
      case 0:
        return <Crown className="h-5 w-5 text-yellow-500" />;
      case 1:
        return <Medal className="h-5 w-5 text-gray-400" />;
      case 2:
        return <Award className="h-5 w-5 text-amber-600" />;
      default:
        return <span className="text-sm font-medium text-muted-foreground">#{index + 1}</span>;
    }
  };

  const getLevelBadge = (level: number, confidence?: number) => {
    const isLowConfidence = (confidence || 0) < 0.2;
    const badgeStyle = isLowConfidence ? "opacity-60" : "";

    if (level >= 5.0) return <Badge className={`bg-purple-500/10 text-purple-500 border-purple-500/20 ${badgeStyle}`}>Pro</Badge>;
    if (level >= 4.5) return <Badge className={`bg-indigo-500/10 text-indigo-500 border-indigo-500/20 ${badgeStyle}`}>Champion</Badge>;
    if (level >= 4.0) return <Badge className={`bg-blue-500/10 text-blue-500 border-blue-500/20 ${badgeStyle}`}>Adv Tournament</Badge>;
    if (level >= 3.5) return <Badge className={`bg-cyan-500/10 text-cyan-500 border-cyan-500/20 ${badgeStyle}`}>Adv Intermediate</Badge>;
    if (level >= 3.0) return <Badge className={`bg-green-500/10 text-green-500 border-green-500/20 ${badgeStyle}`}>Intermediate</Badge>;
    if (level >= 2.5) return <Badge className={`bg-yellow-500/10 text-yellow-500 border-yellow-500/20 ${badgeStyle}`}>Adv Beginner</Badge>;
    return <Badge className={`bg-orange-500/10 text-orange-500 border-orange-500/20 ${badgeStyle}`}>Beginner</Badge>;
  };

  const getWinRateTrend = (winRate: number) => {
    if (winRate >= 60) return <TrendingUp className="h-4 w-4 text-green-500" />;
    if (winRate <= 40) return <TrendingDown className="h-4 w-4 text-red-500" />;
    return <Minus className="h-4 w-4 text-muted-foreground" />;
  };

  // ---- Payments tab state ----
  const [selectedSessionId, setSelectedSessionId] = useState<string>("");
  const [paymentStatuses, setPaymentStatuses] = useState<Record<string, boolean>>({});

  const { data: sessions = [] } = useQuery({
    queryKey: ["sessions-with-fees", selectedClubId],
    queryFn: async () => {
      if (!selectedClubId) return [];
      const { data, error } = await supabase
        .from("sessions")
        .select("id, Date, Venue, fee_per_player")
        .eq("club_id", selectedClubId)
        .gt("fee_per_player", 0)
        .order("Date", { ascending: false });
      if (error) throw error;
      return data as Session[];
    },
    enabled: !!selectedClubId && isAdmin,
  });

  const { data: registrations = [] } = useQuery({
    queryKey: ["session-registrations", selectedSessionId],
    queryFn: async () => {
      if (!selectedSessionId) return [];
      const { data, error } = await supabase
        .from("session_registrations")
        .select(`id, user_id, status, fee_amount, user_profiles!inner (first_name, last_name, email)`)
        .eq("session_id", selectedSessionId)
        .eq("status", "registered");
      if (error) throw error;
      return data as SessionRegistration[];
    },
    enabled: !!selectedSessionId && isAdmin,
  });

  const { data: currentPaymentStatuses = [] } = useQuery({
    queryKey: ["payment-statuses", selectedSessionId],
    queryFn: async () => {
      if (!selectedSessionId) return [];
      const { data, error } = await supabase
        .from("session_payments")
        .select("registration_id, paid")
        .eq("session_id", selectedSessionId);
      if (error) throw error;
      return data as PaymentStatus[];
    },
    enabled: !!selectedSessionId && isAdmin,
  });

  useEffect(() => {
    const statusMap: Record<string, boolean> = {};
    registrations.forEach((reg) => {
      const existingStatus = currentPaymentStatuses.find((ps) => ps.registration_id === reg.id);
      statusMap[reg.id] = existingStatus?.paid ?? false;
    });
    setPaymentStatuses(statusMap);
  }, [registrations, currentPaymentStatuses]);

  const updatePaymentStatus = useMutation({
    mutationFn: async ({ registrationId, paid }: { registrationId: string; paid: boolean }) => {
      const { error } = await supabase.from("session_payments").upsert(
        {
          session_id: selectedSessionId,
          registration_id: registrationId,
          paid: paid,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "session_id,registration_id" }
      );
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payment-statuses", selectedSessionId] });
      toast.success("Payment status updated");
    },
    onError: () => {
      toast.error("Failed to update payment status");
    },
  });

  const handlePaymentToggle = (registrationId: string, paid: boolean) => {
    setPaymentStatuses((prev) => ({ ...prev, [registrationId]: paid }));
    updatePaymentStatus.mutate({ registrationId, paid });
  };

  const selectedSession = sessions.find((s) => s.id.toString() === selectedSessionId);
  const totalPlayers = registrations.length;
  const expectedTotal = selectedSession ? selectedSession.fee_per_player * totalPlayers : 0;
  const paidCount = Object.values(paymentStatuses).filter(Boolean).length;
  const collectedAmount = selectedSession ? selectedSession.fee_per_player * paidCount : 0;

  // ---- Club Settings Dialog ----
  const [settingsOpen, setSettingsOpen] = useState(false);

  // Parse location for display
  const getLocationDisplay = (): string => {
    if (!selectedClub?.location) return "No location set";
    if (typeof selectedClub.location === "string") {
      try {
        const parsed = JSON.parse(selectedClub.location);
        return Array.isArray(parsed) ? parsed.join(", ") : selectedClub.location;
      } catch {
        return selectedClub.location;
      }
    }
    return Array.isArray(selectedClub.location) ? (selectedClub.location as string[]).join(", ") : "No location set";
  };

  return (
    <div className="space-y-8">
      {/* Club Header */}
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-foreground font-anybody">
            {selectedClub?.name || "Club"}
          </h1>
          {selectedClub?.description && (
            <p className="text-muted-foreground mt-2">{selectedClub.description}</p>
          )}
          <div className="flex items-center gap-2 mt-2 text-sm text-muted-foreground">
            <MapPin className="h-4 w-4" />
            <span>{getLocationDisplay()}</span>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <AddParticipantDialog />
          {isAdmin && (
            <Dialog open={settingsOpen} onOpenChange={setSettingsOpen}>
              <DialogTrigger asChild>
                <Button variant="outline" className="flex items-center gap-2">
                  <Settings className="h-4 w-4" />
                  Club Settings
                </Button>
              </DialogTrigger>
              <DialogContent className="sm:max-w-[425px] bg-card border-border">
                <DialogHeader>
                  <DialogTitle className="text-card-foreground">Club Settings</DialogTitle>
                  <DialogDescription className="text-muted-foreground">
                    Manage your club configuration and preferences.
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4 py-4">
                  <div>
                    <p className="text-sm font-medium text-card-foreground">Club Name</p>
                    <p className="text-sm text-muted-foreground">{selectedClub?.name}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-card-foreground">Description</p>
                    <p className="text-sm text-muted-foreground">{selectedClub?.description || "No description"}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-card-foreground">Locations</p>
                    <p className="text-sm text-muted-foreground">{getLocationDisplay()}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-card-foreground">Total Members</p>
                    <p className="text-sm text-muted-foreground">{totalMembers}</p>
                  </div>
                </div>
                <div className="flex justify-end">
                  <Button variant="outline" onClick={() => setSettingsOpen(false)}>
                    Close
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          )}
        </div>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="members" className="w-full">
        <TabsList className={isAdmin ? "grid w-full grid-cols-3" : "grid w-full grid-cols-2"}>
          <TabsTrigger value="members">Members</TabsTrigger>
          <TabsTrigger value="rankings">Rankings</TabsTrigger>
          {isAdmin && <TabsTrigger value="payments">Payments</TabsTrigger>}
        </TabsList>

        {/* ===================== MEMBERS TAB ===================== */}
        <TabsContent value="members">
          <div className="space-y-6 mt-4">
            {/* Member Stats */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
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
                    <p className="text-2xl font-bold text-card-foreground">{activeMembers}</p>
                  </div>
                  <Activity className="h-8 w-8 text-chart-2" />
                </div>
              </Card>
              <Card className="p-6 bg-card border-border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">New Members</p>
                    <p className="text-2xl font-bold text-card-foreground">{newMembers}</p>
                  </div>
                  <UserPlus className="h-8 w-8 text-chart-3" />
                </div>
              </Card>
              <Card className="p-6 bg-card border-border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Avg Level</p>
                    <p className="text-2xl font-bold text-card-foreground">{averageLevel}</p>
                  </div>
                  <Trophy className="h-8 w-8 text-chart-4" />
                </div>
              </Card>
            </div>

            {/* Search */}
            <Card className="p-6 bg-card border-border">
              <form onSubmit={handleSearch} className="space-y-4">
                <div className="flex flex-col sm:flex-row gap-4">
                  <div className="relative flex-1">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      value={searchInput}
                      onChange={(e) => setSearchInput(e.target.value)}
                      placeholder="Search members by name or email..."
                      className="pl-10 bg-background border-input"
                    />
                  </div>
                  <div className="flex gap-2">
                    <Button type="submit" className="flex-1 sm:flex-none">
                      Search
                    </Button>
                    <Button type="button" variant="outline" onClick={handleClearSearch} className="flex-1 sm:flex-none">
                      Clear
                    </Button>
                  </div>
                </div>
              </form>
            </Card>

            {/* Members List */}
            <Card className="bg-card border-border">
              <div className="p-6">
                <h2 className="text-xl font-semibold text-card-foreground mb-4">
                  Member Directory {selectedClub && `- ${selectedClub.name}`}
                </h2>

                {membersLoading ? (
                  <div className="text-center py-8">
                    <div className="text-muted-foreground">Loading members...</div>
                  </div>
                ) : membersError ? (
                  <div className="text-center py-8">
                    <div className="text-destructive">Failed to load members</div>
                  </div>
                ) : !selectedClub ? (
                  <div className="text-center py-8">
                    <div className="text-muted-foreground">Please select a club to view members</div>
                  </div>
                ) : filteredMembers.length === 0 ? (
                  <div className="text-center py-8">
                    <div className="text-muted-foreground">
                      {searchQuery ? "No members found matching your search" : "No members in this club yet"}
                    </div>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {filteredMembers.map((member) => (
                      <div
                        key={member.id}
                        className="p-4 border border-border rounded-lg bg-background hover:bg-accent/50 transition-colors cursor-pointer"
                        onClick={() => navigate(`/member/${member.user_id}`)}
                      >
                        <div className="flex items-start justify-between mb-3">
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-1">
                              <h3 className="font-semibold text-foreground">
                                {member.user_metadata?.full_name || "Unknown Member"}
                              </h3>
                              {member.role === "admin" && <Crown className="h-4 w-4 text-primary" />}
                            </div>
                            <p className="text-sm text-muted-foreground">{member.user_metadata?.email}</p>
                          </div>
                          <Badge variant={member.role === "admin" ? "default" : "secondary"}>
                            {member.role === "admin" ? "Admin" : "Member"}
                          </Badge>
                        </div>

                        <div className="space-y-2">
                          <div className="flex justify-between text-sm">
                            <span className="text-muted-foreground">Level:</span>
                            <span className="font-medium">{member.level}</span>
                          </div>
                          <div className="flex justify-between text-sm">
                            <span className="text-muted-foreground">Games:</span>
                            <span className="font-medium">{member.total_games_played}</span>
                          </div>
                          <div className="flex justify-between text-sm">
                            <span className="text-muted-foreground">Win Rate:</span>
                            <span className="font-medium">
                              {member.total_games_played && member.total_games_played > 0
                                ? `${Math.round(((member.wins || 0) / member.total_games_played) * 100)}%`
                                : "N/A"}
                            </span>
                          </div>
                          <div className="flex justify-between text-sm">
                            <span className="text-muted-foreground">Joined:</span>
                            <span className="font-medium">{new Date(member.joined_at).toLocaleDateString()}</span>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </Card>
          </div>
        </TabsContent>

        {/* ===================== RANKINGS TAB ===================== */}
        <TabsContent value="rankings">
          <div className="space-y-6 mt-4">
            {/* Overview Stats */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <Card className="p-6 bg-card border-border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Total Players</p>
                    <p className="text-2xl font-bold text-card-foreground">{processedParticipants.length}</p>
                  </div>
                  <Trophy className="h-8 w-8 text-chart-1" />
                </div>
              </Card>
              <Card className="p-6 bg-card border-border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Average Level</p>
                    <p className="text-2xl font-bold text-card-foreground">
                      {processedParticipants.length > 0
                        ? (processedParticipants.reduce((sum, p) => sum + (p.skill_level || 0), 0) / processedParticipants.length).toFixed(2)
                        : "0.00"}
                    </p>
                  </div>
                  <BarChart3 className="h-8 w-8 text-chart-2" />
                </div>
              </Card>
              <Card className="p-6 bg-card border-border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Top Player</p>
                    <p className="text-2xl font-bold text-card-foreground">
                      {processedParticipants[0] ? processedParticipants[0].name.split(" ")[0] : "N/A"}
                    </p>
                  </div>
                  <Crown className="h-8 w-8 text-chart-3" />
                </div>
              </Card>
              <Card className="p-6 bg-card border-border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Avg Win Rate</p>
                    <p className="text-2xl font-bold text-card-foreground">
                      {processedParticipants.length > 0
                        ? (processedParticipants.reduce((sum, p) => sum + p.winRate, 0) / processedParticipants.length).toFixed(1)
                        : "0.0"}
                      %
                    </p>
                  </div>
                  <Star className="h-8 w-8 text-chart-4" />
                </div>
              </Card>
            </div>

            {/* Filters and Sorting */}
            <Card className="p-6 bg-card border-border">
              <div className="flex flex-col sm:flex-row gap-4">
                <div className="flex-1">
                  <label className="text-sm font-medium text-card-foreground mb-2 block">Sort by</label>
                  <Select value={sortBy} onValueChange={(value: SortOption) => setSortBy(value)}>
                    <SelectTrigger className="bg-background border-input">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-popover border-border">
                      <SelectItem value="level">Skill Level</SelectItem>
                      <SelectItem value="winrate">Win Rate</SelectItem>
                      <SelectItem value="games">Games Played</SelectItem>
                      <SelectItem value="wins">Total Wins</SelectItem>
                      <SelectItem value="confidence">Rating Confidence</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex-1">
                  <label className="text-sm font-medium text-card-foreground mb-2 block">Filter</label>
                  <Select value={filterBy} onValueChange={(value: FilterOption) => setFilterBy(value)}>
                    <SelectTrigger className="bg-background border-input">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-popover border-border">
                      <SelectItem value="all">All Players</SelectItem>
                      <SelectItem value="active">Active Players</SelectItem>
                      <SelectItem value="male">Male Players</SelectItem>
                      <SelectItem value="female">Female Players</SelectItem>
                      <SelectItem value="low-confidence">Low Confidence Ratings</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </Card>

            {/* Rankings Table */}
            <Card className="bg-card border-border">
              <div className="p-6">
                <h2 className="text-xl font-semibold text-card-foreground mb-6">Leaderboard</h2>

                {rankingsLoading ? (
                  <div className="text-center py-8">
                    <div className="text-muted-foreground">Loading rankings...</div>
                  </div>
                ) : rankingsError ? (
                  <div className="text-center py-8">
                    <div className="text-destructive">Failed to load rankings</div>
                  </div>
                ) : !selectedClub ? (
                  <div className="text-center py-8">
                    <div className="text-muted-foreground">Please select a club to view rankings</div>
                  </div>
                ) : processedParticipants.length > 0 ? (
                  <div className="space-y-4">
                    {processedParticipants.map((participant, index) => (
                      <div
                        key={participant.id}
                        className={`flex items-center gap-4 p-4 rounded-lg border transition-colors cursor-pointer ${
                          index < 3 ? "border-primary/20 bg-primary/5" : "border-border bg-accent/5 hover:bg-accent/10"
                        }`}
                        onClick={() => navigate(`/member/${participant.id}`)}
                      >
                        <div className="flex items-center justify-center w-8">{getRankIcon(index)}</div>
                        <div className="flex items-center gap-3 flex-1 min-w-0">
                          <Avatar className="h-10 w-10">
                            <AvatarImage src={participant.avatar_url || undefined} />
                            <AvatarFallback className="text-sm bg-sidebar-accent text-sidebar-accent-foreground">
                              {participant.name.charAt(0)}
                            </AvatarFallback>
                          </Avatar>
                          <div className="flex-1 min-w-0">
                            <p className="font-medium text-card-foreground truncate">{participant.name}</p>
                            <div className="flex items-center gap-2 mt-1">
                              {getLevelBadge(participant.skill_level || 0, participant.rating_confidence)}
                              <span className="text-xs text-muted-foreground">
                                {participant.gender === "M" ? "Male" : "Female"}
                              </span>
                              {(participant.rating_confidence || 0) < 0.2 && (
                                <Badge variant="outline" className="text-xs bg-orange-500/10 text-orange-600 border-orange-500/20">
                                  <AlertTriangle className="h-3 w-3 mr-1" />
                                  Low Confidence
                                </Badge>
                              )}
                            </div>
                          </div>
                        </div>
                        <div className="hidden sm:flex items-center gap-6 text-sm">
                          <div className="text-center">
                            <p className="font-medium text-card-foreground">{participant.skill_level?.toFixed(2) || "0.00"}</p>
                            <p className="text-xs text-muted-foreground">Level</p>
                          </div>
                          <div className="text-center">
                            <div className="flex items-center gap-1">
                              <p className="font-medium text-card-foreground">{participant.winRate.toFixed(1)}%</p>
                              {getWinRateTrend(participant.winRate)}
                            </div>
                            <p className="text-xs text-muted-foreground">Win Rate</p>
                          </div>
                          <div className="text-center">
                            <p className="font-medium text-card-foreground">{participant.total_games_played}</p>
                            <p className="text-xs text-muted-foreground">Games</p>
                          </div>
                          <div className="text-center">
                            <p className="font-medium text-green-500">{participant.wins}</p>
                            <p className="text-xs text-muted-foreground">Wins</p>
                          </div>
                          <div className="text-center">
                            <div className="flex items-center gap-1">
                              <p className="font-medium text-card-foreground">
                                {((participant.rating_confidence || 0) * 100).toFixed(1)}%
                              </p>
                              {(participant.rating_confidence || 0) < 0.2 && <AlertTriangle className="h-3 w-3 text-orange-500" />}
                            </div>
                            <p className="text-xs text-muted-foreground">Confidence</p>
                          </div>
                        </div>
                        <div className="sm:hidden text-right">
                          <p className="font-medium text-card-foreground">{participant.skill_level?.toFixed(2) || "0.00"}</p>
                          <p className="text-xs text-muted-foreground">
                            {participant.wins}W / {participant.total_games_played}G
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center text-muted-foreground py-8">
                    {participants && participants.length === 0
                      ? "No participants in this club yet"
                      : "No players found matching the current filters."}
                  </div>
                )}
              </div>
            </Card>
          </div>
        </TabsContent>

        {/* ===================== PAYMENTS TAB (admin only) ===================== */}
        {isAdmin && (
          <TabsContent value="payments">
            <div className="space-y-6 mt-4">
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
                          {format(new Date(session.Date), "PPP")} - {session.Venue} ({"\u00A3"}
                          {session.fee_per_player.toFixed(2)})
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
                            <p className="text-2xl font-bold text-card-foreground">{"\u00A3"}{expectedTotal.toFixed(2)}</p>
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
                            <p className="text-2xl font-bold text-green-500">{"\u00A3"}{collectedAmount.toFixed(2)}</p>
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
                            <p className="text-2xl font-bold text-red-500">{"\u00A3"}{(expectedTotal - collectedAmount).toFixed(2)}</p>
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
                          <p className="font-medium">{format(new Date(selectedSession.Date), "PPP")}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Venue</p>
                          <p className="font-medium">{selectedSession.Venue}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Fee per Player</p>
                          <p className="font-medium">{"\u00A3"}{selectedSession.fee_per_player.toFixed(2)}</p>
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
                                  onCheckedChange={(checked) => handlePaymentToggle(registration.id, checked as boolean)}
                                />
                                <div>
                                  <p className="font-medium">
                                    {registration.user_profiles.first_name} {registration.user_profiles.last_name}
                                  </p>
                                  <p className="text-sm text-muted-foreground">{registration.user_profiles.email}</p>
                                </div>
                              </div>
                              <div className="flex items-center gap-4">
                                <span className="font-medium">
                                  {"\u00A3"}{registration.fee_amount?.toFixed(2) || selectedSession.fee_per_player.toFixed(2)}
                                </span>
                                <Badge
                                  variant={paymentStatuses[registration.id] ? "default" : "secondary"}
                                  className={
                                    paymentStatuses[registration.id]
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
          </TabsContent>
        )}
      </Tabs>
    </div>
  );
};

export default Club;
