import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface PushNotificationRequest {
  user_ids: string[];
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Max-Age': '86400',
      },
    });
  }

  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        status: 405,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  }

  try {
    const requestData: PushNotificationRequest = await req.json();

    const { user_ids, title, body, data } = requestData;
    if (!user_ids || !Array.isArray(user_ids) || user_ids.length === 0 || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_ids, title, body' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Look up active device tokens for the given users
    const { data: tokens, error: tokensError } = await supabaseClient
      .from('device_tokens')
      .select('user_id, token, platform')
      .in('user_id', user_ids)
      .eq('is_active', true);

    if (tokensError) {
      console.error('Error fetching device tokens:', tokensError);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch device tokens' }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    console.log(`[send-push-notification] Found ${tokens?.length ?? 0} active device tokens for ${user_ids.length} users`);
    console.log(`[send-push-notification] Title: ${title}`);
    console.log(`[send-push-notification] Body: ${body}`);
    if (data) {
      console.log(`[send-push-notification] Data:`, JSON.stringify(data));
    }

    // TODO: Send actual APNs push notifications once certificates are configured
    // For now, log tokens and return success
    for (const token of tokens ?? []) {
      console.log(`[send-push-notification] Would send to user ${token.user_id} on ${token.platform}: ${token.token.substring(0, 8)}...`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        tokens_found: tokens?.length ?? 0,
        message: 'Push notification logged (APNs sending not yet configured)',
      }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );

  } catch (error) {
    console.error('Error processing push notification request:', error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  }
});
