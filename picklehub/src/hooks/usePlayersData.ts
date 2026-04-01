
import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import { PlayerData } from "@/types/court-display";

export const usePlayersData = () => {
  const [players, setPlayers] = useState<{ [key: string]: PlayerData }>({});

  useEffect(() => {
    const fetchPlayers = async () => {
      const { data, error } = await supabase
        .from('participants')
        .select('name, gender');
      
      if (error) {
        console.error('Error fetching players:', error);
        return;
      }

      const playersMap = data.reduce<{ [key: string]: PlayerData }>((acc, player) => {
        acc[player.name] = { name: player.name, gender: player.gender };
        return acc;
      }, {});

      setPlayers(playersMap);
    };

    fetchPlayers();
  }, []);

  return players;
};
