export interface Court {
  team1: string[];
  team2: string[];
}

export interface Rotation {
  courts: Court[];
  resters: string[];
  id?: string;
}

export interface Participant {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  skill_level?: number;
  gender?: string;
  total_games_played?: number;
  wins?: number;
  losses?: number;
  level?: number;
  avatar_url?: string;
  user_data?: any;
  preferences?: any;
  created_at?: string;
  updated_at?: string;
  club_id?: string;
}

export interface Session {
  id: string;
  Date: string;
  Venue: string;
  Status: 'Upcoming' | 'Completed' | 'Ready';
}

export interface RotationSettings {
  count: number;
  minRestCount?: number;
}
