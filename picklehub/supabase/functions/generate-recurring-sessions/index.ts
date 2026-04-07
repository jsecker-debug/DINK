import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: {
        ...corsHeaders,
        "Access-Control-Max-Age": "86400",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }

  try {
    const { session_id } = await req.json();

    if (!session_id) {
      return new Response(
        JSON.stringify({ error: "Missing required field: session_id" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        },
      );
    }

    // Fetch the template session
    const { data: template, error: fetchError } = await supabase
      .from("sessions")
      .select("*")
      .eq("id", session_id)
      .single();

    if (fetchError || !template) {
      return new Response(
        JSON.stringify({ error: "Session not found", details: fetchError }),
        {
          status: 404,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        },
      );
    }

    const config = template.recurring_config;
    if (!config) {
      return new Response(
        JSON.stringify({ error: "Session has no recurring configuration" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        },
      );
    }

    const frequency: string = config.frequency;
    const maxOccurrences: number = config.max_occurrences || 8;
    const templateDate = new Date(template.Date);

    const sessions = [];
    const groupId = crypto.randomUUID();

    for (let i = 1; i < maxOccurrences; i++) {
      const newDate = new Date(templateDate);

      if (frequency === "weekly") {
        newDate.setDate(newDate.getDate() + 7 * i);
      } else if (frequency === "biweekly") {
        newDate.setDate(newDate.getDate() + 14 * i);
      } else if (frequency === "monthly") {
        newDate.setMonth(newDate.getMonth() + i);
      }

      const dateString = newDate.toISOString().split("T")[0];

      sessions.push({
        club_id: template.club_id,
        Date: dateString,
        Venue: template.Venue,
        venue_id: template.venue_id,
        fee_per_player: template.fee_per_player,
        max_participants: template.max_participants,
        start_time: template.start_time,
        end_time: template.end_time,
        session_type: template.session_type,
        parent_session_id: template.id,
        group_id: groupId,
        Status: "Upcoming",
        is_template: false,
      });
    }

    const { error: insertError } = await supabase
      .from("sessions")
      .insert(sessions);

    if (insertError) {
      return new Response(
        JSON.stringify({
          error: "Failed to insert recurring sessions",
          details: insertError,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        },
      );
    }

    return new Response(
      JSON.stringify({ success: true, count: sessions.length }),
      {
        headers: { "Content-Type": "application/json", ...corsHeaders },
      },
    );
  } catch (error) {
    console.error("Error generating recurring sessions:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      },
    );
  }
});
