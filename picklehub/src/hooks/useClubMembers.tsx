import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { useClub } from "@/contexts/ClubContext";
import { useAuth } from "@/contexts/AuthContext";

export type ClubMember = {
  id: string;
  user_id: string;
  role: 'admin' | 'member';
  status: 'active' | 'pending' | 'inactive';
  joined_at: string;
  user_metadata?: {
    full_name?: string;
    email?: string;
  };
  profile?: {
    phone?: string;
    bio?: string;
  };
  // Mock data for now - will be replaced with actual stats later
  total_games_played?: number;
  wins?: number;
  losses?: number;
  level?: number;
}

export const useClubMembers = () => {
  const { selectedClubId } = useClub();
  const { user } = useAuth();
  
  return useQuery({
    queryKey: ["club-members", selectedClubId],
    queryFn: async () => {
      if (!selectedClubId) {
        return [];
      }
      
      // For now, we'll create a simpler query and mock the user data
      // In a real app, you'd want to create a database function or view that joins this data
      const { data, error } = await supabase
        .from("club_memberships")
        .select(`
          id,
          user_id,
          role,
          status,
          joined_at
        `)
        .eq("club_id", selectedClubId)
        .eq("status", "active");
        
      if (error) {
        console.error("Error fetching club members:", error);
        throw error;
      }
      
      console.log("DEBUG: Club memberships data:", data);
      
      // Now get the actual user profiles for these members
      const userIds = (data || []).map(member => member.user_id);
      
      console.log("DEBUG: User IDs to fetch profiles for:", userIds);
      
      if (userIds.length === 0) {
        console.log("DEBUG: No user IDs found, returning empty array");
        return [];
      }
      
      const { data: profiles, error: profileError } = await supabase
        .from('user_profiles')
        .select('id, first_name, last_name, phone, skill_level, gender, total_games_played, wins, losses, avatar_url')
        .in('id', userIds);
        
      console.log("DEBUG: User profiles data:", profiles);
      console.log("DEBUG: User profiles error:", profileError);
        
      if (profileError) {
        console.error('Error fetching user profiles:', profileError);
        // Fall back to basic membership data
        console.log("DEBUG: Falling back to basic membership data");
        return (data || []).map(member => ({
          id: member.id,
          user_id: member.user_id,
          role: member.role,
          status: member.status,
          joined_at: member.joined_at,
          user_metadata: {
            full_name: 'Unknown User',
            email: member.user_id === user?.id ? user?.email : 'Email not available',
          },
          total_games_played: 0,
          wins: 0,
          losses: 0,
          level: 0,
        })) as ClubMember[];
      }
      
      // Combine membership data with user profiles
      const membersWithProfiles = (data || []).map((member) => {
        const profile = profiles?.find(p => p.id === member.user_id);
        const fullName = profile ? `${profile.first_name || ''} ${profile.last_name || ''}`.trim() : '';
        
        return {
          id: member.id,
          user_id: member.user_id,
          role: member.role,
          status: member.status,
          joined_at: member.joined_at,
          user_metadata: {
            full_name: fullName || 'Unknown User',
            email: member.user_id === user?.id ? user?.email : 'Email not available',
          },
          profile: {
            phone: profile?.phone || '',
            bio: `Club member since ${new Date(member.joined_at).getFullYear()}`,
          },
          total_games_played: profile?.total_games_played || 0,
          wins: profile?.wins || 0,
          losses: profile?.losses || 0,
          level: profile?.skill_level || 0,
        };
      }) as ClubMember[];
      
      console.log("DEBUG: Final members with profiles:", membersWithProfiles);
      
      return membersWithProfiles;
    },
    enabled: !!selectedClubId,
  });
};