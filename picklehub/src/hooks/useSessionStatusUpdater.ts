import { useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import { useQueryClient } from '@tanstack/react-query';

export const useSessionStatusUpdater = () => {
  const queryClient = useQueryClient();

  useEffect(() => {
    const updateSessionStatuses = async () => {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Get all upcoming sessions
      const { data: sessions, error } = await supabase
        .from('sessions')
        .select('*')
        .eq('Status', 'Upcoming');

      if (error) {
        console.error('Error fetching sessions:', error);
        return;
      }

      // Filter sessions that should be marked as completed
      const sessionsToUpdate = sessions.filter(session => {
        const sessionDate = new Date(session.Date);
        sessionDate.setHours(0, 0, 0, 0);
        return sessionDate < today;
      });

      if (sessionsToUpdate.length === 0) return;

      // Update sessions to completed
      const { error: updateError } = await supabase
        .from('sessions')
        .update({ Status: 'Completed' })
        .in('id', sessionsToUpdate.map(s => s.id));

      if (updateError) {
        console.error('Error updating sessions:', updateError);
        return;
      }

      // Invalidate sessions query to refresh the UI
      queryClient.invalidateQueries({ queryKey: ['sessions'] });
    };

    // Run immediately and then every hour
    updateSessionStatuses();
    const interval = setInterval(updateSessionStatuses, 60 * 60 * 1000);

    return () => clearInterval(interval);
  }, [queryClient]);
}; 