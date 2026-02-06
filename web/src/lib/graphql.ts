const apiUrl = import.meta.env.VITE_API_URL ?? '/api/graphql';

export async function gqlFetch(query: string, variables: Record<string, unknown> = {}) {
  const response = await fetch(apiUrl, {
    method: 'POST',
    headers: {
      'content-type': 'application/json'
    },
    body: JSON.stringify({ query, variables })
  });

  if (!response.ok) {
    throw new Error(`GraphQL request failed (${response.status})`);
  }

  const payload = await response.json();

  if (payload.errors?.length) {
    throw new Error(payload.errors[0].message || 'GraphQL error');
  }

  return payload.data;
}
