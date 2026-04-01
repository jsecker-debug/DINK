export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
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
      roation_resters: {
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
      sessions: {
        Row: {
          created_at: string
          Date: string | null
          group_id: string | null
          id: number
          scores_entered: boolean | null
          Status: string | null
          Venue: string | null
        }
        Insert: {
          created_at?: string
          Date?: string | null
          group_id?: string | null
          id?: number
          scores_entered?: boolean | null
          Status?: string | null
          Venue?: string | null
        }
        Update: {
          created_at?: string
          Date?: string | null
          group_id?: string | null
          id?: number
          scores_entered?: boolean | null
          Status?: string | null
          Venue?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_group_member_emails: {
        Args: {
          group_id_param: string
        }
        Returns: {
          user_id: string
          email: string
        }[]
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

type PublicSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (PublicSchema["Tables"] & PublicSchema["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (PublicSchema["Tables"] &
        PublicSchema["Views"])
    ? (PublicSchema["Tables"] &
        PublicSchema["Views"])[PublicTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof PublicSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof PublicSchema["Enums"]
    ? PublicSchema["Enums"][PublicEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof PublicSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof PublicSchema["CompositeTypes"]
    ? PublicSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never
