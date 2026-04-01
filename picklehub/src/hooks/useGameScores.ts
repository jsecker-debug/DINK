import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/contexts/AuthContext";

export interface GameScore {
  id?: string;
  session_id: number;
  court_number: number;
  rotation_number: number;
  team1_players: string[];
  team2_players: string[];
  game_number: number;
  team1_score: number;
  team2_score: number;
  created_at?: string;
  created_by?: string;
}

// Get scores for a specific session
export const useSessionGameScores = (sessionId: string) => {
  return useQuery({
    queryKey: ["session-game-scores", sessionId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("game_scores")
        .select("*")
        .eq("session_id", parseInt(sessionId))
        .order("court_number", { ascending: true })
        .order("rotation_number", { ascending: true })
        .order("game_number", { ascending: true });

      if (error) throw error;
      return data as GameScore[];
    },
    enabled: !!sessionId,
  });
};

// Get scores for a specific court and rotation
export const useCourtGameScores = (sessionId: string, courtNumber: number, rotationNumber: number) => {
  return useQuery({
    queryKey: ["court-game-scores", sessionId, courtNumber, rotationNumber],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("game_scores")
        .select("*")
        .eq("session_id", parseInt(sessionId))
        .eq("court_number", courtNumber)
        .eq("rotation_number", rotationNumber)
        .order("game_number", { ascending: true });

      if (error) throw error;
      return data as GameScore[];
    },
    enabled: !!sessionId && courtNumber > 0 && rotationNumber > 0,
  });
};

// Save scores for a court and update player ratings
export const useSaveGameScores = () => {
  const queryClient = useQueryClient();
  const { user } = useAuth();

  return useMutation({
    mutationFn: async (params: {
      sessionId: number;
      courtNumber: number;
      rotationNumber: number;
      team1Players: string[];
      team2Players: string[];
      scores: Array<{ game_number: number; team1_score: number; team2_score: number }>;
    }) => {
      const { sessionId, courtNumber, rotationNumber, team1Players, team2Players, scores } = params;

      // First, delete existing scores for this court/rotation
      await supabase
        .from("game_scores")
        .delete()
        .eq("session_id", sessionId)
        .eq("court_number", courtNumber)
        .eq("rotation_number", rotationNumber);

      // Insert new scores
      const gameScores = scores.map(score => ({
        session_id: sessionId,
        court_number: courtNumber,
        rotation_number: rotationNumber,
        team1_players: team1Players,
        team2_players: team2Players,
        game_number: score.game_number,
        team1_score: score.team1_score,
        team2_score: score.team2_score,
        created_by: user?.id
      }));

      const { data, error } = await supabase
        .from("game_scores")
        .insert(gameScores)
        .select();

      if (error) throw error;

      // Immediately update player ratings for this specific game
      console.log("🎯 Starting immediate rating update for court/rotation:", courtNumber, rotationNumber);
      
      const ratingUpdateResult = await supabase.rpc('update_game_ratings', {
        p_session_id: sessionId,
        p_court_number: courtNumber,
        p_rotation_number: rotationNumber,
        p_team1_players: team1Players,
        p_team2_players: team2Players,
        p_team1_scores: scores.map(s => s.team1_score),
        p_team2_scores: scores.map(s => s.team2_score)
      });

      if (ratingUpdateResult.error) {
        console.error("Rating update error:", ratingUpdateResult.error);
        throw new Error(`Failed to update ratings: ${ratingUpdateResult.error.message}`);
      }

      console.log("✅ Rating update result:", ratingUpdateResult.data);
      return { gameScores: data, ratingUpdates: ratingUpdateResult.data };
    },
    onSuccess: (result, variables) => {
      // Invalidate relevant queries
      queryClient.invalidateQueries({ queryKey: ["session-game-scores", variables.sessionId.toString()] });
      queryClient.invalidateQueries({ 
        queryKey: ["court-game-scores", variables.sessionId.toString(), variables.courtNumber, variables.rotationNumber] 
      });
      
      // Invalidate user profile and ranking queries to show updated ratings
      queryClient.invalidateQueries({ queryKey: ["participants"] });
      queryClient.invalidateQueries({ queryKey: ["club-members"] });
      
      console.log("📊 Rating changes applied:", result.ratingUpdates);
    },
  });
};

// Trigger rating updates for a session
export const useTriggerRatingUpdates = () => {
  return useMutation({
    mutationFn: async (sessionId: number) => {
      const { data, error } = await supabase.rpc('update_session_ratings', { 
        session_id: sessionId 
      });

      if (error) throw error;
      return data;
    },
  });
};