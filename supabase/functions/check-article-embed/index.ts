const allowedOrigins = new Set<string>([
  "https://stadtschreiber.app",
  "https://www.stadtschreiber.app",
  "http://localhost:5000",
  "http://localhost:3000",
]);

const embeddingOrigins = [
  "https://stadtschreiber.app",
  "https://www.stadtschreiber.app",
  "http://localhost:5000",
  "http://localhost:3000",
];

const maximumRedirects = 5;
const requestTimeoutMilliseconds = 10000;

Deno.serve(async (request: Request): Promise<Response> => {
  const corsHeaders = createCorsHeaders(request);

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
    const requestBody: unknown = await request.json();

    if (
      requestBody === null ||
      typeof requestBody !== "object" ||
      Array.isArray(requestBody)
    ) {
      return jsonResponse(
        {
          error: "invalid_request_body",
        },
        400,
        corsHeaders,
      );
    }

    const body = requestBody as Record<string, unknown>;
    const articleUrl = body["url"];

    if (
      typeof articleUrl !== "string" ||
      articleUrl.trim().length === 0
    ) {
      return jsonResponse(
        {
          error: "invalid_url",
        },
        400,
        corsHeaders,
      );
    }

    const normalizedUrl = parseAllowedUrl(
      articleUrl.trim(),
    );

    if (normalizedUrl === null) {
      return jsonResponse(
        {
          url: articleUrl.trim(),
          canEmbed: false,
          reason: "invalid_or_disallowed_url",
        },
        200,
        corsHeaders,
      );
    }

    const embedResult = await inspectUrl(
      normalizedUrl,
    );

    return jsonResponse(
      embedResult,
      200,
      corsHeaders,
    );
  } catch (error) {
    console.error(
      "check-article-embed failed",
      error,
    );

    return jsonResponse(
      {
        error: "embed_check_failed",
      },
      500,
      corsHeaders,
    );
  }
});

async function inspectUrl(
  initialUrl: URL,
): Promise<Record<string, unknown>> {
  const controller = new AbortController();

  const timeoutHandle = setTimeout(
    () => controller.abort(),
    requestTimeoutMilliseconds,
  );

  try {
    const fetchResult = await fetchWithRedirectValidation(
      initialUrl,
      controller.signal,
    );

    if (fetchResult.error !== null) {
      return {
        url: initialUrl.toString(),
        finalUrl: fetchResult.finalUrl,
        statusCode: fetchResult.statusCode,
        canEmbed: false,
        reason: fetchResult.error,
      };
    }

    const response = fetchResult.response;

    if (response === null) {
      return {
        url: initialUrl.toString(),
        finalUrl: fetchResult.finalUrl,
        canEmbed: false,
        reason: "empty_response",
      };
    }

    const finalUrl = new URL(
      fetchResult.finalUrl,
    );

    const xFrameOptions = response.headers
        .get("x-frame-options")
        ?.trim() ??
        null;

    const contentSecurityPolicy = response.headers
        .get("content-security-policy")
        ?.trim() ??
        null;

    const contentType = response.headers
        .get("content-type")
        ?.trim() ??
        null;

    const statusCode = response.status;

    if (statusCode < 200 || statusCode >= 400) {
      return {
        url: initialUrl.toString(),
        finalUrl: finalUrl.toString(),
        statusCode,
        canEmbed: false,
        reason: "http_error",
        xFrameOptions,
        contentSecurityPolicy,
        contentType,
      };
    }

    const xFrameResult = evaluateXFrameOptions(
      xFrameOptions,
      finalUrl,
    );

    if (!xFrameResult.canEmbed) {
      return {
        url: initialUrl.toString(),
        finalUrl: finalUrl.toString(),
        statusCode,
        canEmbed: false,
        reason: xFrameResult.reason,
        xFrameOptions,
        contentSecurityPolicy,
        contentType,
      };
    }

    const cspResult =
        evaluateContentSecurityPolicy(
      contentSecurityPolicy,
      finalUrl,
    );

    if (!cspResult.canEmbed) {
      return {
        url: initialUrl.toString(),
        finalUrl: finalUrl.toString(),
        statusCode,
        canEmbed: false,
        reason: cspResult.reason,
        xFrameOptions,
        contentSecurityPolicy,
        contentType,
      };
    }

    if (
      contentType !== null &&
      !contentType.toLowerCase().contains(
        "text/html",
      ) &&
      !contentType.toLowerCase().contains(
        "application/xhtml+xml",
      )
    ) {
      return {
        url: initialUrl.toString(),
        finalUrl: finalUrl.toString(),
        statusCode,
        canEmbed: false,
        reason: "unsupported_content_type",
        xFrameOptions,
        contentSecurityPolicy,
        contentType,
      };
    }

    return {
      url: initialUrl.toString(),
      finalUrl: finalUrl.toString(),
      statusCode,
      canEmbed: true,
      reason: "no_blocking_headers_found",
      xFrameOptions,
      contentSecurityPolicy,
      contentType,
    };
  } catch (error) {
    if (
      error instanceof DOMException &&
      error.name === "AbortError"
    ) {
      return {
        url: initialUrl.toString(),
        canEmbed: false,
        reason: "request_timeout",
      };
    }

    console.error(
      "Article request failed",
      error,
    );

    return {
      url: initialUrl.toString(),
      canEmbed: false,
      reason: "request_failed",
    };
  } finally {
    clearTimeout(timeoutHandle);
  }
}

async function fetchWithRedirectValidation(
  initialUrl: URL,
  signal: AbortSignal,
): Promise<FetchValidationResult> {
  let currentUrl = initialUrl;

  for (
    let redirectCount = 0;
    redirectCount <= maximumRedirects;
    redirectCount += 1
  ) {
    const response = await fetch(
      currentUrl.toString(),
      {
        method: "GET",
        redirect: "manual",
        signal,
        headers: {
          "Accept":
              "text/html,application/xhtml+xml",
          "User-Agent":
              "Stadtschreiber-Embed-Checker/1.0",
        },
      },
    );

    if (!isRedirectStatus(response.status)) {
      return {
        response,
        finalUrl: currentUrl.toString(),
        statusCode: response.status,
        error: null,
      };
    }

    const location = response.headers.get(
      "location",
    );

    if (location === null || location.isEmpty) {
      return {
        response: null,
        finalUrl: currentUrl.toString(),
        statusCode: response.status,
        error: "redirect_without_location",
      };
    }

    const redirectUrl = new URL(
      location,
      currentUrl,
    );

    const validatedRedirectUrl = parseAllowedUrl(
      redirectUrl.toString(),
    );

    if (validatedRedirectUrl === null) {
      return {
        response: null,
        finalUrl: redirectUrl.toString(),
        statusCode: response.status,
        error: "redirected_to_disallowed_url",
      };
    }

    currentUrl = validatedRedirectUrl;
  }

  return {
    response: null,
    finalUrl: currentUrl.toString(),
    statusCode: null,
    error: "too_many_redirects",
  };
}

function evaluateXFrameOptions(
  value: string | null,
  targetUrl: URL,
): EmbedEvaluation {
  if (value === null || value.length === 0) {
    return {
      canEmbed: true,
      reason: "x_frame_options_missing",
    };
  }

  const normalizedValue = value.toLowerCase();

  if (normalizedValue.includes("deny")) {
    return {
      canEmbed: false,
      reason: "x_frame_options_deny",
    };
  }

  if (
    normalizedValue.includes("sameorigin")
  ) {
    const targetOrigin =
        targetUrl.origin.toLowerCase();

    const sameOriginAllowed =
        embeddingOrigins.some(
      (origin) =>
          origin.toLowerCase() === targetOrigin,
    );

    return {
      canEmbed: sameOriginAllowed,
      reason: sameOriginAllowed
          ? "x_frame_options_sameorigin_allowed"
          : "x_frame_options_sameorigin_blocked",
    };
  }

  return {
    canEmbed: true,
    reason: "x_frame_options_not_blocking",
  };
}

function evaluateContentSecurityPolicy(
  value: string | null,
  targetUrl: URL,
): EmbedEvaluation {
  if (value === null || value.length === 0) {
    return {
      canEmbed: true,
      reason: "frame_ancestors_missing",
    };
  }

  const policies = value
      .split(",")
      .map((policy) => policy.trim())
      .filter((policy) => policy.length > 0);

  for (const policy of policies) {
    const directives = policy
        .split(";")
        .map((directive) => directive.trim())
        .filter(
          (directive) =>
              directive.length > 0,
        );

    for (const directive of directives) {
      const parts = directive
          .split(/\s+/)
          .filter((part) => part.length > 0);

      if (
        parts.length === 0 ||
        parts[0].toLowerCase() !==
            "frame-ancestors"
      ) {
        continue;
      }

      const sources = parts
          .slice(1)
          .map((source) => source.toLowerCase());

      if (sources.includes("'none'")) {
        return {
          canEmbed: false,
          reason:
              "csp_frame_ancestors_none",
        };
      }

      const embeddingAllowed =
          embeddingOrigins.some(
        (embeddingOrigin) =>
            isEmbeddingOriginAllowed(
          embeddingOrigin,
          targetUrl.origin,
          sources,
        ),
      );

      if (!embeddingAllowed) {
        return {
          canEmbed: false,
          reason:
              "csp_frame_ancestors_not_allowed",
        };
      }
    }
  }

  return {
    canEmbed: true,
    reason: "csp_frame_ancestors_allowed",
  };
}

function isEmbeddingOriginAllowed(
  embeddingOrigin: string,
  targetOrigin: string,
  sources: string[],
): boolean {
  const normalizedEmbeddingOrigin =
      embeddingOrigin.toLowerCase();

  const embeddingUrl = new URL(
    normalizedEmbeddingOrigin,
  );

  if (sources.includes("*")) {
    return true;
  }

  if (
    sources.includes("'self'") &&
    normalizedEmbeddingOrigin ===
        targetOrigin.toLowerCase()
  ) {
    return true;
  }

  for (const source of sources) {
    if (
      source === "*" ||
      source === "'none'" ||
      source === "'self'"
    ) {
      continue;
    }

    if (
      source === "https:" &&
      embeddingUrl.protocol === "https:"
    ) {
      return true;
    }

    if (
      source === "http:" &&
      embeddingUrl.protocol === "http:"
    ) {
      return true;
    }

    if (
      matchesHostSource(
        embeddingUrl,
        source,
      )
    ) {
      return true;
    }
  }

  return false;
}

function matchesHostSource(
  embeddingUrl: URL,
  source: string,
): boolean {
  let sourceUrl: URL;

  try {
    if (
      source.startsWith("http://") ||
      source.startsWith("https://")
    ) {
      sourceUrl = new URL(source);
    } else {
      sourceUrl = new URL(
        `${embeddingUrl.protocol}//${source}`,
      );
    }
  } catch {
    return false;
  }

  const sourceHostname =
      sourceUrl.hostname.toLowerCase();

  const embeddingHostname =
      embeddingUrl.hostname.toLowerCase();

  const protocolMatches =
      source.startsWith("http://") ||
      source.startsWith("https://")
      ? sourceUrl.protocol ===
          embeddingUrl.protocol
      : true;

  if (!protocolMatches) {
    return false;
  }

  const portMatches =
      sourceUrl.port.length === 0 ||
      sourceUrl.port === embeddingUrl.port;

  if (!portMatches) {
    return false;
  }

  if (sourceHostname.startsWith("*.")) {
    const hostnameSuffix =
        sourceHostname.substring(2);

    return embeddingHostname.endsWith(
      `.${hostnameSuffix}`,
    );
  }

  return sourceHostname === embeddingHostname;
}

function parseAllowedUrl(
  value: string,
): URL | null {
  let url: URL;

  try {
    url = new URL(value);
  } catch {
    return null;
  }

  if (
    url.protocol !== "http:" &&
    url.protocol !== "https:"
  ) {
    return null;
  }

  if (url.username.length > 0) {
    return null;
  }

  if (url.password.length > 0) {
    return null;
  }

  const hostname = url.hostname.toLowerCase();

  if (
    hostname === "localhost" ||
    hostname === "0.0.0.0" ||
    hostname === "::1" ||
    hostname.endsWith(".local")
  ) {
    return null;
  }

  if (isPrivateIpv4(hostname)) {
    return null;
  }

  return url;
}

function isPrivateIpv4(
  hostname: string,
): boolean {
  const stringParts = hostname.split(".");

  if (stringParts.length !== 4) {
    return false;
  }

  const parts = stringParts.map(
    (part) => Number.parseInt(part, 10),
  );

  if (
    parts.some(
      (part) => Number.isNaN(part),
    )
  ) {
    return false;
  }

  const first = parts[0];
  const second = parts[1];

  if (
    first === 0 ||
    first === 10 ||
    first === 127
  ) {
    return true;
  }

  if (
    first === 172 &&
    second >= 16 &&
    second <= 31
  ) {
    return true;
  }

  if (
    first === 192 &&
    second === 168
  ) {
    return true;
  }

  if (
    first === 169 &&
    second === 254
  ) {
    return true;
  }

  return first >= 224;
}

function isRedirectStatus(
  statusCode: number,
): boolean {
  return statusCode === 301 ||
      statusCode === 302 ||
      statusCode === 303 ||
      statusCode === 307 ||
      statusCode === 308;
}

function createCorsHeaders(
  request: Request,
): Record<string, string> {
  const origin = request.headers.get(
    "Origin",
  );

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
    "Access-Control-Max-Age": "3600",
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

type EmbedEvaluation = {
  canEmbed: boolean;
  reason: string;
};

type FetchValidationResult = {
  response: Response | null;
  finalUrl: string;
  statusCode: number | null;
  error: string | null;
};