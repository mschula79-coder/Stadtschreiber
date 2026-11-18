import {
  createClient,
} from "npm:@supabase/supabase-js@2";

const allowedOrigins = new Set<string>([
  "https://stadtschreiber.app",
  "https://www.stadtschreiber.app",
  "http://localhost:5000",
  "http://localhost:3000",
]);

Deno.serve(
  async (
    request: Request,
  ): Promise<Response> => {
    const corsHeaders =
        createCorsHeaders(request);

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders,
      });
    }

    if (request.method !== "POST") {
      return jsonResponse(
        {
          error: "method_not_allowed",
        },
        405,
        corsHeaders,
      );
    }

    try {
      const authorizationHeader =
          request.headers.get(
        "Authorization",
      );

      if (
        authorizationHeader === null ||
        !authorizationHeader.startsWith(
          "Bearer ",
        )
      ) {
        return jsonResponse(
          {
            error:
                "missing_authorization_header",
          },
          401,
          corsHeaders,
        );
      }

      const accessToken =
          authorizationHeader
              .substring(
                "Bearer ".length,
              )
              .trim();

      if (accessToken.length === 0) {
        return jsonResponse(
          {
            error: "missing_access_token",
          },
          401,
          corsHeaders,
        );
      }

      const supabaseUrl =
          getRequiredEnvironmentVariable(
        "SUPABASE_URL",
      );

      const supabaseAnonKey =
          getRequiredEnvironmentVariable(
        "SUPABASE_ANON_KEY",
      );

      const serviceRoleKey =
          getRequiredEnvironmentVariable(
        "SUPABASE_SERVICE_ROLE_KEY",
      );

      const userClient = createClient(
        supabaseUrl,
        supabaseAnonKey,
        {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
          },
          global: {
            headers: {
              Authorization:
                  `Bearer ${accessToken}`,
            },
          },
        },
      );

      const {
        data: userData,
        error: userError,
      } = await userClient.auth.getUser(
        accessToken,
      );

      if (
        userError !== null ||
        userData.user === null
      ) {
        console.error(
          "User authentication failed",
          userError,
        );

        return jsonResponse(
          {
            error: "invalid_credentials",
          },
          401,
          corsHeaders,
        );
      }

      const authenticatedUserId =
          userData.user.id;

      const adminClient = createClient(
        supabaseUrl,
        serviceRoleKey,
        {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
          },
        },
      );

      const {
        error: deleteError,
      } = await adminClient.auth.admin
          .deleteUser(
        authenticatedUserId,
      );

      if (deleteError !== null) {
        console.error(
          "User deletion failed",
          deleteError,
        );

        return jsonResponse(
          {
            error: "user_deletion_failed",
            message: deleteError.message,
          },
          500,
          corsHeaders,
        );
      }

      return jsonResponse(
        {
          success: true,
        },
        200,
        corsHeaders,
      );
    } catch (error) {
      console.error(
        "delete-user failed",
        error,
      );

      return jsonResponse(
        {
          error: "internal_server_error",
        },
        500,
        corsHeaders,
      );
    }
  },
);

function getRequiredEnvironmentVariable(
  name: string,
): string {
  const value = Deno.env.get(name)?.trim();

  if (
    value === undefined ||
    value.length === 0
  ) {
    throw new Error(
      `Missing environment variable: ${name}`,
    );
  }

  return value;
}

function createCorsHeaders(
  request: Request,
): Record<string, string> {
  const origin =
      request.headers.get("Origin");

  const allowedOrigin =
      origin !== null &&
      allowedOrigins.has(origin)
      ? origin
      : "https://stadtschreiber.app";

  return {
    "Access-Control-Allow-Origin":
        allowedOrigin,
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods":
        "POST, OPTIONS",
    "Access-Control-Max-Age":
        "3600",
    "Vary": "Origin",
  };
}

function jsonResponse(
  body: Record<string, unknown>,
  status: number,
  corsHeaders: Record<string, string>,
): Response {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: {
        ...corsHeaders,
        "Content-Type":
            "application/json; charset=utf-8",
      },
    },
  );
}