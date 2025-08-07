import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { Resend } from "npm:resend@4.7.0";

const resend = new Resend(Deno.env.get('RESEND_API_KEY'));

interface InviteEmailRequest {
  recipientEmail: string;
  recipientName?: string;
  clubName: string;
  inviterName: string;
  inviteUrl: string;
  personalMessage?: string;
}

const createInviteEmailTemplate = (data: InviteEmailRequest): string => {
  const { recipientName, clubName, inviterName, inviteUrl, personalMessage } = data;
  
  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>You're Invited to Join ${clubName}</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background-color: #f9fafb;
        }
        .container {
          background: white;
          border-radius: 12px;
          padding: 32px;
          box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
        }
        .header {
          text-align: center;
          margin-bottom: 32px;
        }
        .logo {
          width: 60px;
          height: 60px;
          background: linear-gradient(135deg, #3b82f6, #1d4ed8);
          border-radius: 50%;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          margin-bottom: 16px;
        }
        .logo svg {
          width: 30px;
          height: 30px;
          color: white;
        }
        h1 {
          color: #1f2937;
          font-size: 24px;
          font-weight: 600;
          margin: 0 0 8px 0;
        }
        .subtitle {
          color: #6b7280;
          font-size: 16px;
          margin: 0;
        }
        .content {
          margin-bottom: 32px;
        }
        .invitation-details {
          background: #f3f4f6;
          border-radius: 8px;
          padding: 20px;
          margin: 20px 0;
        }
        .personal-message {
          background: #eff6ff;
          border-left: 4px solid #3b82f6;
          padding: 16px;
          margin: 20px 0;
          border-radius: 0 8px 8px 0;
        }
        .cta-button {
          display: inline-block;
          background: #3b82f6;
          color: white;
          text-decoration: none;
          padding: 12px 24px;
          border-radius: 8px;
          font-weight: 600;
          text-align: center;
          margin: 20px 0;
        }
        .cta-button:hover {
          background: #2563eb;
        }
        .footer {
          text-align: center;
          color: #6b7280;
          font-size: 14px;
          margin-top: 32px;
          padding-top: 24px;
          border-top: 1px solid #e5e7eb;
        }
        .steps {
          margin: 24px 0;
        }
        .step {
          display: flex;
          align-items: center;
          margin: 12px 0;
          padding: 8px 0;
        }
        .step-number {
          background: #3b82f6;
          color: white;
          width: 24px;
          height: 24px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 12px;
          font-weight: 600;
          margin-right: 12px;
          flex-shrink: 0;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">
            <svg viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2L2 7L12 12L22 7L12 2Z" />
              <path d="M2 17L12 22L22 17" />
              <path d="M2 12L12 17L22 12" />
            </svg>
          </div>
          <h1>You're Invited!</h1>
          <p class="subtitle">Join ${clubName} and start playing pickleball</p>
        </div>

        <div class="content">
          <p>Hi${recipientName ? ` ${recipientName}` : ''},</p>
          
          <p><strong>${inviterName}</strong> has invited you to join <strong>${clubName}</strong> on our pickleball platform!</p>

          ${personalMessage ? `
            <div class="personal-message">
              <strong>Personal message from ${inviterName}:</strong><br>
              "${personalMessage}"
            </div>
          ` : ''}

          <div class="invitation-details">
            <h3 style="margin-top: 0; color: #1f2937;">What's next?</h3>
            <div class="steps">
              <div class="step">
                <div class="step-number">1</div>
                <div>Click the invitation link below</div>
              </div>
              <div class="step">
                <div class="step-number">2</div>
                <div>Create your account (or sign in if you already have one)</div>
              </div>
              <div class="step">
                <div class="step-number">3</div>
                <div>You'll automatically be added to ${clubName}</div>
              </div>
              <div class="step">
                <div class="step-number">4</div>
                <div>Start registering for sessions and playing!</div>
              </div>
            </div>
          </div>

          <div style="text-align: center;">
            <a href="${inviteUrl}" class="cta-button">Accept Invitation</a>
          </div>

          <p style="color: #6b7280; font-size: 14px;">
            <strong>Note:</strong> This invitation link will expire in 7 days. If you already have an account, 
            simply sign in and the invitation will be automatically applied.
          </p>
        </div>

        <div class="footer">
          <p>This invitation was sent by ${inviterName} from ${clubName}.</p>
          <p>If you didn't expect this invitation, you can safely ignore this email.</p>
        </div>
      </div>
    </body>
    </html>
  `;
};

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
        headers: { 'Content-Type': 'application/json', ...corsHeaders } 
      }
    );
  }

  try {
    const requestData: InviteEmailRequest = await req.json();
    
    // Validate required fields
    const { recipientEmail, clubName, inviterName, inviteUrl } = requestData;
    if (!recipientEmail || !clubName || !inviterName || !inviteUrl) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json', ...corsHeaders } 
        }
      );
    }

    const emailTemplate = createInviteEmailTemplate(requestData);
    
    const result = await resend.emails.send({
      from: 'Pickleball Squad <invites@drinkgroni.com>',
      to: [recipientEmail],
      subject: `You're invited to join ${clubName}!`,
      html: emailTemplate,
    });

    if (result.error) {
      console.error('Resend API error:', result.error);
      return new Response(
        JSON.stringify({ error: result.error.message }),
        { 
          status: 500, 
          headers: { 'Content-Type': 'application/json', ...corsHeaders } 
        }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        messageId: result.data?.id 
      }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );

  } catch (error) {
    console.error('Error sending invite email:', error);
    return new Response(
      JSON.stringify({ 
        error: error instanceof Error ? error.message : 'Unknown error occurred' 
      }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json', ...corsHeaders } 
      }
    );
  }
});