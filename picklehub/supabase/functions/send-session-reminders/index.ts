import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
        "Access-Control-Max-Age": "86400",
      },
    });
  }

  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };

  try {
    // 1. Find sessions within the next 48 hours that are upcoming
    const now = new Date();
    const in48Hours = new Date(now.getTime() + 48 * 60 * 60 * 1000);

    const { data: sessions, error: sessionsError } = await supabase
      .from("sessions")
      .select("id, Date, Venue, Status, club_id, start_time")
      .eq("Status", "upcoming");

    if (sessionsError) {
      console.error("Error fetching sessions:", sessionsError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch sessions" }),
        {
          status: 500,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }

    // Filter sessions within the 48-hour window
    const upcomingSessions = (sessions ?? []).filter((session) => {
      if (!session.Date || !session.start_time) return false;

      // Combine date + start_time into a full datetime
      const sessionDateStr = session.Date;
      const startTime = new Date(session.start_time);
      const hours = startTime.getUTCHours().toString().padStart(2, "0");
      const minutes = startTime.getUTCMinutes().toString().padStart(2, "0");
      const sessionDateTime = new Date(
        `${sessionDateStr}T${hours}:${minutes}:00`
      );

      return sessionDateTime > now && sessionDateTime <= in48Hours;
    });

    console.log(
      `[send-session-reminders] Found ${upcomingSessions.length} sessions within 48 hours`
    );

    let totalNotificationsSent = 0;

    for (const session of upcomingSessions) {
      // 2. Check if reminder was already sent for this session
      const { data: existingReminders, error: reminderCheckError } =
        await supabase
          .from("session_reminders")
          .select("id")
          .eq("session_id", session.id)
          .eq("reminder_type", "48h_auto");

      if (reminderCheckError) {
        console.error(
          `Error checking reminders for session ${session.id}:`,
          reminderCheckError
        );
        continue;
      }

      if (existingReminders && existingReminders.length > 0) {
        console.log(
          `[send-session-reminders] Reminder already sent for session ${session.id}, skipping`
        );
        continue;
      }

      // 3. Get club members who are NOT registered for this session
      const { data: clubMembers, error: membersError } = await supabase
        .from("club_memberships")
        .select("user_id")
        .eq("club_id", session.club_id)
        .eq("status", "active");

      if (membersError) {
        console.error(
          `Error fetching members for club ${session.club_id}:`,
          membersError
        );
        continue;
      }

      const { data: registrations, error: regsError } = await supabase
        .from("session_registrations")
        .select("user_id")
        .eq("session_id", session.id);

      if (regsError) {
        console.error(
          `Error fetching registrations for session ${session.id}:`,
          regsError
        );
        continue;
      }

      const registeredUserIds = new Set(
        (registrations ?? []).map((r) => r.user_id)
      );
      const unregisteredMembers = (clubMembers ?? []).filter(
        (m) => !registeredUserIds.has(m.user_id)
      );

      console.log(
        `[send-session-reminders] Session ${session.id}: ${unregisteredMembers.length} unregistered members`
      );

      if (unregisteredMembers.length === 0) continue;

      // 4. Insert notification records for each unregistered member
      const notificationInserts = unregisteredMembers.map((member) => ({
        user_id: member.user_id,
        title: "Session Reminder",
        body: `Pickleball session at ${session.Venue ?? "TBD"} in 2 days. Don't forget to register!`,
        type: "session_reminder",
        data: { session_id: session.id, club_id: session.club_id },
        read: false,
      }));

      const { error: notifError } = await supabase
        .from("notifications")
        .insert(notificationInserts);

      if (notifError) {
        console.error(
          `Error inserting notifications for session ${session.id}:`,
          notifError
        );
        continue;
      }

      // 5. Insert session_reminders record to mark as sent
      const { error: reminderInsertError } = await supabase
        .from("session_reminders")
        .insert({
          session_id: session.id,
          reminder_type: "48h_auto",
          sent_at: new Date().toISOString(),
          recipients_count: unregisteredMembers.length,
        });

      if (reminderInsertError) {
        console.error(
          `Error inserting session_reminder for session ${session.id}:`,
          reminderInsertError
        );
      }

      totalNotificationsSent += unregisteredMembers.length;
    }

    return new Response(
      JSON.stringify({
        success: true,
        sessions_processed: upcomingSessions.length,
        notifications_sent: totalNotificationsSent,
      }),
      { headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (error) {
    console.error("Error processing session reminders:", error);
    return new Response(
      JSON.stringify({
        error:
          error instanceof Error ? error.message : "Unknown error occurred",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
});
