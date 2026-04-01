import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useClub } from "@/contexts/ClubContext";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  ArrowLeft,
  Crown,
  Trophy,
  Target,
  TrendingDown,
  BarChart3,
  Shield,
  UserMinus,
} from "lucide-react";

const MemberDetail = () => {
  const { memberId } = useParams<{ memberId: string }>();
  const navigate = useNavigate();
  const { selectedClub, selectedClubId } = useClub();
  const { user } = useAuth();
  const queryClient = useQueryClient();

  // Admin check
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

  // Fetch member profile
  const {
    data: memberProfile,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["member-profile", memberId],
    queryFn: async () => {
      if (!memberId) return null;
      const { data, error } = await supabase
        .from("user_profiles")
        .select(
          "id, first_name, last_name, phone, skill_level, gender, total_games_played, wins, losses, avatar_url, rating_confidence"
        )
        .eq("id", memberId)
        .single();
      if (error) throw error;
      return data;
    },
    enabled: !!memberId,
  });

  // Fetch membership info (role, joined_at)
  const { data: membership } = useQuery({
    queryKey: ["member-membership", memberId, selectedClubId],
    queryFn: async () => {
      if (!memberId || !selectedClubId) return null;
      const { data, error } = await supabase
        .from("club_memberships")
        .select("id, role, status, joined_at")
        .eq("user_id", memberId)
        .eq("club_id", selectedClubId)
        .single();
      if (error) throw error;
      return data;
    },
    enabled: !!memberId && !!selectedClubId,
  });

  // Change role handler
  const handleChangeRole = async (newRole: string) => {
    if (!membership?.id) return;
    const { error } = await supabase
      .from("club_memberships")
      .update({ role: newRole })
      .eq("id", membership.id);

    if (error) {
      toast.error("Failed to update role");
      return;
    }
    toast.success(`Role updated to ${newRole}`);
    queryClient.invalidateQueries({ queryKey: ["member-membership", memberId, selectedClubId] });
    queryClient.invalidateQueries({ queryKey: ["club-members", selectedClubId] });
  };

  // Remove from club handler
  const handleRemoveFromClub = async () => {
    if (!membership?.id) return;
    const { error } = await supabase
      .from("club_memberships")
      .update({ status: "inactive" })
      .eq("id", membership.id);

    if (error) {
      toast.error("Failed to remove member");
      return;
    }
    toast.success("Member removed from club");
    queryClient.invalidateQueries({ queryKey: ["club-members", selectedClubId] });
    navigate("/club");
  };

  const fullName = memberProfile
    ? `${memberProfile.first_name || ""} ${memberProfile.last_name || ""}`.trim() || "Unknown Member"
    : "Loading...";
  const gamesPlayed = memberProfile?.total_games_played || 0;
  const wins = memberProfile?.wins || 0;
  const losses = memberProfile?.losses || 0;
  const winRate = gamesPlayed > 0 ? Math.round((wins / gamesPlayed) * 100) : 0;

  if (isLoading) {
    return (
      <div className="h-full flex items-center justify-center">
        <div className="text-muted-foreground">Loading member details...</div>
      </div>
    );
  }

  if (error || !memberProfile) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" onClick={() => navigate("/club")} className="flex items-center gap-2">
          <ArrowLeft className="h-4 w-4" />
          Back to Club
        </Button>
        <Card className="p-8 text-center">
          <div className="text-destructive">Member not found</div>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Back button */}
      <Button variant="ghost" onClick={() => navigate("/club")} className="flex items-center gap-2">
        <ArrowLeft className="h-4 w-4" />
        Back to Club
      </Button>

      {/* Profile Header */}
      <Card className="p-8 bg-card border-border">
        <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
          <Avatar className="h-24 w-24">
            <AvatarImage src={memberProfile.avatar_url || undefined} />
            <AvatarFallback className="text-2xl bg-sidebar-accent text-sidebar-accent-foreground">
              {fullName.charAt(0)}
            </AvatarFallback>
          </Avatar>

          <div className="flex-1 text-center sm:text-left">
            <div className="flex items-center gap-3 justify-center sm:justify-start">
              <h1 className="text-3xl font-bold text-foreground">{fullName}</h1>
              {membership?.role === "admin" && <Crown className="h-6 w-6 text-primary" />}
            </div>
            <div className="mt-2 space-y-1">
              <p className="text-muted-foreground">
                Skill Level: <span className="font-medium text-foreground">{memberProfile.skill_level?.toFixed(2) || "Unrated"}</span>
              </p>
              {memberProfile.gender && (
                <p className="text-muted-foreground">
                  Gender: <span className="font-medium text-foreground">{memberProfile.gender === "M" ? "Male" : "Female"}</span>
                </p>
              )}
              {membership?.joined_at && (
                <p className="text-muted-foreground">
                  Member since: <span className="font-medium text-foreground">{new Date(membership.joined_at).toLocaleDateString()}</span>
                </p>
              )}
            </div>
            <div className="mt-3">
              <Badge variant={membership?.role === "admin" ? "default" : "secondary"}>
                {membership?.role === "admin" ? "Admin" : "Member"}
              </Badge>
            </div>
          </div>
        </div>
      </Card>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Games Played</p>
              <p className="text-2xl font-bold text-card-foreground">{gamesPlayed}</p>
            </div>
            <BarChart3 className="h-8 w-8 text-chart-1" />
          </div>
        </Card>

        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Wins</p>
              <p className="text-2xl font-bold text-green-500">{wins}</p>
            </div>
            <Trophy className="h-8 w-8 text-green-500" />
          </div>
        </Card>

        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Losses</p>
              <p className="text-2xl font-bold text-red-500">{losses}</p>
            </div>
            <TrendingDown className="h-8 w-8 text-red-500" />
          </div>
        </Card>

        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Win Rate</p>
              <p className="text-2xl font-bold text-card-foreground">{winRate}%</p>
            </div>
            <Target className="h-8 w-8 text-chart-4" />
          </div>
        </Card>
      </div>

      {/* Rating Confidence */}
      {memberProfile.rating_confidence !== null && memberProfile.rating_confidence !== undefined && (
        <Card className="p-6 bg-card border-border">
          <h2 className="text-lg font-semibold text-card-foreground mb-4">Rating Details</h2>
          <div className="flex items-center gap-4">
            <div>
              <p className="text-sm text-muted-foreground">Rating Confidence</p>
              <p className="text-xl font-bold text-card-foreground">
                {((memberProfile.rating_confidence || 0) * 100).toFixed(1)}%
              </p>
            </div>
            {(memberProfile.rating_confidence || 0) < 0.2 && (
              <Badge variant="outline" className="bg-orange-500/10 text-orange-600 border-orange-500/20">
                Low Confidence - needs more games
              </Badge>
            )}
          </div>
        </Card>
      )}

      {/* Admin Section */}
      {isAdmin && membership && (
        <Card className="p-6 bg-card border-border">
          <h2 className="text-lg font-semibold text-card-foreground mb-4 flex items-center gap-2">
            <Shield className="h-5 w-5" />
            Admin Actions
          </h2>
          <div className="flex flex-col sm:flex-row gap-4">
            {/* Change Role */}
            <div className="flex items-center gap-3">
              <span className="text-sm font-medium text-muted-foreground">Role:</span>
              <Select
                value={membership.role}
                onValueChange={handleChangeRole}
              >
                <SelectTrigger className="w-[140px] bg-background border-input">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent className="bg-popover border-border">
                  <SelectItem value="member">Member</SelectItem>
                  <SelectItem value="admin">Admin</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Remove from Club */}
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="destructive" className="flex items-center gap-2">
                  <UserMinus className="h-4 w-4" />
                  Remove from Club
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent className="bg-card border-border">
                <AlertDialogHeader>
                  <AlertDialogTitle>Remove Member</AlertDialogTitle>
                  <AlertDialogDescription>
                    Are you sure you want to remove <strong>{fullName}</strong> from{" "}
                    <strong>{selectedClub?.name}</strong>? This action can be undone by re-inviting the member.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                  <AlertDialogAction onClick={handleRemoveFromClub} className="bg-destructive text-destructive-foreground">
                    Remove
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </Card>
      )}
    </div>
  );
};

export default MemberDetail;
