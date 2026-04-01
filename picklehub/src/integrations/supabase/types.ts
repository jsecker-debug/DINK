export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.4"
  }
  public: {
    Tables: {
      activities: {
        Row: {
          actor_id: string | null
          club_id: string
          created_at: string | null
          data: Json | null
          id: string
          target_id: string | null
          target_type: string | null
          type: string
        }
        Insert: {
          actor_id?: string | null
          club_id: string
          created_at?: string | null
          data?: Json | null
          id?: string
          target_id?: string | null
          target_type?: string | null
          type: string
        }
        Update: {
          actor_id?: string | null
          club_id?: string
          created_at?: string | null
          data?: Json | null
          id?: string
          target_id?: string | null
          target_type?: string | null
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "activities_club_id_fkey"
            columns: ["club_id"]
            isOneToOne: false
            referencedRelation: "clubs"
            referencedColumns: ["id"]
          },
        ]
      }
      club_invitations: {
        Row: {
          accepted_at: string | null
          accepted_by: string | null
          club_id: string
          created_at: string | null
          email: string
          expires_at: string
          id: string
          invited_by: string
          personal_message: string | null
          status: string
          token: string
        }
        Insert: {
          accepted_at?: string | null
          accepted_by?: string | null
          club_id: string
          created_at?: string | null
          email: string
          expires_at?: string
          id?: string
          invited_by: string
          personal_message?: string | null
          status?: string
          token: string
        }
        Update: {
          accepted_at?: string | null
          accepted_by?: string | null
          club_id?: string
          created_at?: string | null
          email?: string
          expires_at?: string
          id?: string
          invited_by?: string
          personal_message?: string | null
          status?: string
          token?: string
        }
        Relationships: [
          {
            foreignKeyName: "club_invitations_club_id_fkey"
            columns: ["club_id"]
            isOneToOne: false
            referencedRelation: "clubs"
            referencedColumns: ["id"]
          },
        ]
      }
      club_join_requests: {
        Row: {
          club_id: string
          created_at: string | null
          id: string
          message: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          user_data: Json | null
          user_id: string
        }
        Insert: {
          club_id: string
          created_at?: string | null
          id?: string
          message?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          user_data?: Json | null
          user_id: string
        }
        Update: {
          club_id?: string
          created_at?: string | null
          id?: string
          message?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          user_data?: Json | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "club_join_requests_club_id_fkey"
            columns: ["club_id"]
            isOneToOne: false
            referencedRelation: "clubs"
            referencedColumns: ["id"]
          },
        ]
      }
      club_memberships: {
        Row: {
          club_id: string
          created_at: string | null
          id: string
          joined_at: string | null
          participant_id: string | null
          role: string
          status: string | null
          user_id: string | null
        }
        Insert: {
          club_id: string
          created_at?: string | null
          id?: string
          joined_at?: string | null
          participant_id?: string | null
          role: string
          status?: string | null
          user_id?: string | null
        }
        Update: {
          club_id?: string
          created_at?: string | null
          id?: string
          joined_at?: string | null
          participant_id?: string | null
          role?: string
          status?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "club_memberships_club_id_fkey"
            columns: ["club_id"]
            isOneToOne: false
            referencedRelation: "clubs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_club_memberships_club_id"
            columns: ["club_id"]
            isOneToOne: false
            referencedRelation: "clubs"
            referencedColumns: ["id"]
          },
        ]
      }
      clubs: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          location: Json | null
          logo_url: string | null
          name: string
          settings: Json | null
          status: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          location?: Json | null
          logo_url?: string | null
          name: string
          settings?: Json | null
          status?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          location?: Json | null
          logo_url?: string | null
          name?: string
          settings?: Json | null
          status?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      court_assignments: {
        Row: {
          court_number: number | null
          created_at: string
          id: string
          rotation_id: string | null
          team1_players: string[] | null
          team2_players: string[] | null
        }
        Insert: {
          court_number?: number | null
          created_at?: string
          id?: string
          rotation_id?: string | null
          team1_players?: string[] | null
          team2_players?: string[] | null
        }
        Update: {
          court_number?: number | null
          created_at?: string
          id?: string
          rotation_id?: string | null
          team1_players?: string[] | null
          team2_players?: string[] | null
        }
        Relationships: [
          {
            foreignKeyName: "court_assignments_rotation_id_fkey"
            columns: ["rotation_id"]
            isOneToOne: false
            referencedRelation: "rotations"
            referencedColumns: ["id"]
          },
        ]
      }
      game_results: {
        Row: {
          court_number: number | null
          created_at: string | null
          game_number: number | null
          id: string
          is_best_of_three: boolean | null
          losing_team_players: string[]
          losing_team_score: number
          session_id: number | null
          winning_team_players: string[]
          winning_team_score: number
        }
        Insert: {
          court_number?: number | null
          created_at?: string | null
          game_number?: number | null
          id?: string
          is_best_of_three?: boolean | null
          losing_team_players: string[]
          losing_team_score: number
          session_id?: number | null
          winning_team_players: string[]
          winning_team_score: number
        }
        Update: {
          court_number?: number | null
          created_at?: string | null
          game_number?: number | null
          id?: string
          is_best_of_three?: boolean | null
          losing_team_players?: string[]
          losing_team_score?: number
          session_id?: number | null
          winning_team_players?: string[]
          winning_team_score?: number
        }
        Relationships: [
          {
            foreignKeyName: "game_results_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      game_scores: {
        Row: {
          court_number: number
          created_at: string | null
          created_by: string | null
          game_number: number
          id: string
          rotation_number: number
          session_id: number
          team1_players: string[]
          team1_score: number
          team2_players: string[]
          team2_score: number
        }
        Insert: {
          court_number: number
          created_at?: string | null
          created_by?: string | null
          game_number: number
          id?: string
          rotation_number: number
          session_id: number
          team1_players: string[]
          team1_score: number
          team2_players: string[]
          team2_score: number
        }
        Update: {
          court_number?: number
          created_at?: string | null
          created_by?: string | null
          game_number?: number
          id?: string
          rotation_number?: number
          session_id?: number
          team1_players?: string[]
          team1_score?: number
          team2_players?: string[]
          team2_score?: number
        }
        Relationships: [
          {
            foreignKeyName: "game_scores_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      participants: {
        Row: {
          avatar_url: string | null
          created_at: string
          gender: string
          id: string
          level: number | null
          Linked: boolean | null
          losses: number | null
          name: string | null
          rating_confidence: number | null
          rating_volatility: number | null
          total_games_played: number | null
          user_id: string | null
          wins: number | null
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          gender: string
          id?: string
          level?: number | null
          Linked?: boolean | null
          losses?: number | null
          name?: string | null
          rating_confidence?: number | null
          rating_volatility?: number | null
          total_games_played?: number | null
          user_id?: string | null
          wins?: number | null
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          gender?: string
          id?: string
          level?: number | null
          Linked?: boolean | null
          losses?: number | null
          name?: string | null
          rating_confidence?: number | null
          rating_volatility?: number | null
          total_games_played?: number | null
          user_id?: string | null
          wins?: number | null
        }
        Relationships: []
      }
      rotation_resters: {
        Row: {
          created_at: string
          id: string
          resting_players: string[] | null
          rotation_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          resting_players?: string[] | null
          rotation_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          resting_players?: string[] | null
          rotation_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "roation_resters_rotation_id_fkey"
            columns: ["rotation_id"]
            isOneToOne: false
            referencedRelation: "rotations"
            referencedColumns: ["id"]
          },
        ]
      }
      rotations: {
        Row: {
          created_at: string
          group_id: string | null
          id: string
          is_king_court: boolean | null
          last_modified: string | null
          manually_modified: boolean | null
          rotation_number: number | null
          session_id: number | null
        }
        Insert: {
          created_at?: string
          group_id?: string | null
          id?: string
          is_king_court?: boolean | null
          last_modified?: string | null
          manually_modified?: boolean | null
          rotation_number?: number | null
          session_id?: number | null
        }
        Update: {
          created_at?: string
          group_id?: string | null
          id?: string
          is_king_court?: boolean | null
          last_modified?: string | null
          manually_modified?: boolean | null
          rotation_number?: number | null
          session_id?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "rotations_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      session_payments: {
        Row: {
          created_at: string
          id: string
          paid: boolean
          registration_id: string
          session_id: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          paid?: boolean
          registration_id: string
          session_id: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          paid?: boolean
          registration_id?: string
          session_id?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "session_payments_registration_id_fkey"
            columns: ["registration_id"]
            isOneToOne: false
            referencedRelation: "session_registrations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "session_payments_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      session_registrations: {
        Row: {
          fee_amount: number | null
          id: string
          registered_at: string | null
          session_id: number
          status: string | null
          user_id: string
        }
        Insert: {
          fee_amount?: number | null
          id?: string
          registered_at?: string | null
          session_id: number
          status?: string | null
          user_id: string
        }
        Update: {
          fee_amount?: number | null
          id?: string
          registered_at?: string | null
          session_id?: number
          status?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "session_registrations_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "session_registrations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      sessions: {
        Row: {
          club_id: string | null
          created_at: string
          Date: string | null
          end_time: string | null
          fee_per_player: number | null
          group_id: string | null
          id: number
          max_participants: number | null
          registration_deadline: string | null
          scores_entered: boolean | null
          start_time: string | null
          Status: string | null
          Venue: string | null
        }
        Insert: {
          club_id?: string | null
          created_at?: string
          Date?: string | null
          end_time?: string | null
          fee_per_player?: number | null
          group_id?: string | null
          id?: number
          max_participants?: number | null
          registration_deadline?: string | null
          scores_entered?: boolean | null
          start_time?: string | null
          Status?: string | null
          Venue?: string | null
        }
        Update: {
          club_id?: string | null
          created_at?: string
          Date?: string | null
          end_time?: string | null
          fee_per_player?: number | null
          group_id?: string | null
          id?: number
          max_participants?: number | null
          registration_deadline?: string | null
          scores_entered?: boolean | null
          start_time?: string | null
          Status?: string | null
          Venue?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "sessions_club_id_fkey"
            columns: ["club_id"]
            isOneToOne: false
            referencedRelation: "clubs"
            referencedColumns: ["id"]
          },
        ]
      }
      temporary_session_participants: {
        Row: {
          created_at: string | null
          created_by: string
          id: string
          name: string
          notes: string | null
          phone: string | null
          session_id: number
          skill_level: number
        }
        Insert: {
          created_at?: string | null
          created_by: string
          id?: string
          name: string
          notes?: string | null
          phone?: string | null
          session_id: number
          skill_level?: number
        }
        Update: {
          created_at?: string | null
          created_by?: string
          id?: string
          name?: string
          notes?: string | null
          phone?: string | null
          session_id?: number
          skill_level?: number
        }
        Relationships: [
          {
            foreignKeyName: "temporary_session_participants_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      user_profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string | null
          date_of_birth: string | null
          email: string | null
          emergency_contact_name: string | null
          emergency_contact_phone: string | null
          first_name: string | null
          gender: string | null
          id: string
          is_active: boolean | null
          last_name: string | null
          losses: number | null
          phone: string | null
          preferences: Json | null
          rating_confidence: number | null
          rating_volatility: number | null
          skill_level: number | null
          total_games_played: number | null
          updated_at: string | null
          wins: number | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          email?: string | null
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          first_name?: string | null
          gender?: string | null
          id: string
          is_active?: boolean | null
          last_name?: string | null
          losses?: number | null
          phone?: string | null
          preferences?: Json | null
          rating_confidence?: number | null
          rating_volatility?: number | null
          skill_level?: number | null
          total_games_played?: number | null
          updated_at?: string | null
          wins?: number | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          email?: string | null
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          first_name?: string | null
          gender?: string | null
          id?: string
          is_active?: boolean | null
          last_name?: string | null
          losses?: number | null
          phone?: string | null
          preferences?: Json | null
          rating_confidence?: number | null
          rating_volatility?: number | null
          skill_level?: number | null
          total_games_played?: number | null
          updated_at?: string | null
          wins?: number | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_group_member_emails: {
        Args: { group_id_param: string }
        Returns: {
          email: string
          user_id: string
        }[]
      }
      get_player_names: { Args: { player_ids: string[] }; Returns: string[] }
      get_user_clubs: {
        Args: { user_uuid: string }
        Returns: {
          club_id: string
          club_name: string
          role: string
          status: string
        }[]
      }
      log_activity: {
        Args: {
          p_actor_id: string
          p_club_id: string
          p_data?: Json
          p_target_id?: string
          p_target_type?: string
          p_type: string
        }
        Returns: string
      }
      update_game_ratings: {
        Args: {
          p_court_number: number
          p_rotation_number: number
          p_session_id: number
          p_team1_players: string[]
          p_team1_scores: number[]
          p_team2_players: string[]
          p_team2_scores: number[]
        }
        Returns: Json
      }
      update_session_ratings: { Args: { session_id: number }; Returns: Json }
      update_user_game_stats: {
        Args: {
          games_played_delta?: number
          losses_delta?: number
          player_user_id: string
          wins_delta?: number
        }
        Returns: undefined
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
