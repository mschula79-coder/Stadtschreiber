import {
  PutObjectCommand,
  S3Client,
} from "npm:@aws-sdk/client-s3";

import {
  getSignedUrl,
} from "npm:@aws-sdk/s3-request-presigner";

const allowedOrigins = new Set([
  "https://stadtschreiber.app",
  "https://www.stadtschreiber.app",
  "http://localhost:5000",
  "http://localhost:3000",  
]);

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
    const authorization = request.headers.get(
      "Authorization",
    );

    if (
      authorization === null ||
      !authorization.startsWith("Bearer ")
    ) {
      return jsonResponse(
        {
          error: "unauthorized",
        },
        401,
        corsHeaders,
      );
    }

    const accountId = getRequiredSecret(
      "R2_ACCOUNT_ID",
    );

    const accessKeyId = getRequiredSecret(
      "R2_ACCESS_KEY_ID",
    );

    const secretAccessKey = getRequiredSecret(
      "R2_SECRET_ACCESS_KEY",
    );

    const bucketName = getRequiredSecret(
      "R2_BUCKET_NAME",
    );

    const publicBaseUrl = removeTrailingSlashes(
      getRequiredSecret(
        "R2_PUBLIC_BASE_URL",
      ),
    );

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

    const requestedObjectKey = readRequiredString(
      body,
      "objectKey",
    );

    const contentType = readRequiredString(
      body,
      "contentType",
    );

    if (contentType !== "image/webp") {
      return jsonResponse(
        {
          error: "invalid_content_type",
        },
        400,
        corsHeaders,
      );
    }

    const objectKey = sanitizeObjectKey(
      requestedObjectKey,
    );

    if (!objectKey.startsWith("processed/")) {
      return jsonResponse(
        {
          error: "invalid_object_path",
        },
        400,
        corsHeaders,
      );
    }

    if (!objectKey.endsWith(".webp")) {
      return jsonResponse(
        {
          error: "invalid_file_extension",
        },
        400,
        corsHeaders,
      );
    }

    const r2Client = new S3Client({
      region: "auto",
      endpoint:
          `https://${accountId}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId,
        secretAccessKey,
      },
    });

    const putCommand = new PutObjectCommand({
      Bucket: bucketName,
      Key: objectKey,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(
      r2Client,
      putCommand,
      {
        expiresIn: 300,
      },
    );

    const encodedObjectKey = objectKey
        .split("/")
        .map(
          (segment) => encodeURIComponent(segment),
        )
        .join("/");

    const publicUrl =
        `${publicBaseUrl}/${encodedObjectKey}`;

    return jsonResponse(
      {
        uploadUrl,
        publicUrl,
        objectKey,
        expiresIn: 300,
      },
      200,
      corsHeaders,
    );
  } catch (error) {
    console.error(
      "create-r2-upload-url failed",
      error,
    );

    if (error instanceof RequestValidationError) {
      return jsonResponse(
        {
          error: error.errorCode,
        },
        400,
        corsHeaders,
      );
    }

    return jsonResponse(
      {
        error: "upload_url_creation_failed",
      },
      500,
      corsHeaders,
    );
  }
});

class RequestValidationError extends Error {
  readonly errorCode: string;

  constructor(errorCode: string) {
    super(errorCode);
    this.name = "RequestValidationError";
    this.errorCode = errorCode;
  }
}

function createCorsHeaders(
  request: Request,
): Record<string, string> {
  const origin = request.headers.get("Origin");

  const allowedOrigin =
      origin !== null && allowedOrigins.has(origin)
      ? origin
      : "https://stadtschreiber.app";

  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods":
        "POST, OPTIONS",
    "Access-Control-Max-Age": "3600",
    "Vary": "Origin",
  };
}

function getRequiredSecret(
  name: string,
): string {
  const value = Deno.env.get(name);

  if (value === undefined) {
    throw new Error(
      `Missing secret: ${name}`,
    );
  }

  const normalizedValue = value.trim();

  if (normalizedValue.length === 0) {
    throw new Error(
      `Empty secret: ${name}`,
    );
  }

  return normalizedValue;
}

function readRequiredString(
  body: Record<string, unknown>,
  name: string,
): string {
  const value = body[name];

  if (typeof value !== "string") {
    throw new RequestValidationError(
      `invalid_${name}`,
    );
  }

  const normalizedValue = value.trim();

  if (normalizedValue.length === 0) {
    throw new RequestValidationError(
      `invalid_${name}`,
    );
  }

  return normalizedValue;
}

function removeTrailingSlashes(
  value: string,
): string {
  let result = value;

  while (result.endsWith("/")) {
    result = result.substring(
      0,
      result.length - 1,
    );
  }

  return result;
}

function sanitizeObjectKey(
  objectKey: string,
): string {
  const normalizedPath = objectKey.replaceAll(
    "\\",
    "/",
  );

  const sanitizedSegments = normalizedPath
      .split("/")
      .map(
        (segment) => sanitizePathSegment(segment),
      )
      .filter(
        (segment) => segment.length > 0,
      );

  return sanitizedSegments.join("/");
}

function sanitizePathSegment(
  segment: string,
): string {
  let result = "";

  for (const character of segment) {
    const isLowercaseLetter =
        character >= "a" &&
        character <= "z";

    const isUppercaseLetter =
        character >= "A" &&
        character <= "Z";

    const isNumber =
        character >= "0" &&
        character <= "9";

    const isAllowedSymbol =
        character === "." ||
        character === "_" ||
        character === "-";

    if (
      isLowercaseLetter ||
      isUppercaseLetter ||
      isNumber ||
      isAllowedSymbol
    ) {
      result += character;
    } else {
      result += "_";
    }
  }

  while (result.includes("..")) {
    result = result.replaceAll(
      "..",
      ".",
    );
  }

  return result;
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