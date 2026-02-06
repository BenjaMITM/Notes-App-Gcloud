export const NOTES_QUERY = `
  query Notes($limit: Int, $search: String) {
    notes(limit: $limit, search: $search) {
      id
      title
      slug
      updated_at
    }
  }
`;

export const NOTE_QUERY = `
  query Note($id: ID!) {
    note(id: $id) {
      id
      title
      slug
      body
      updated_at
      tags
      mentions
      incoming_links {
        id
        kind
        label
        url
        from_id
        from_note {
          id
          title
          slug
        }
      }
      outgoing_links {
        id
        kind
        label
        url
        to_id
        to_note {
          id
          title
          slug
        }
      }
    }
  }
`;

export const BRAIN_QUERY = `
  query BrainView($id: ID!, $related_limit: Int) {
    brain_view(id: $id, related_limit: $related_limit) {
      focus {
        id
        title
        slug
      }
      parents {
        id
        title
        slug
      }
      children {
        id
        title
        slug
      }
      siblings {
        id
        title
        slug
      }
    }
  }
`;

export const CREATE_NOTE = `
  mutation CreateNote($input: NoteInput!) {
    create_note(input: $input) {
      id
      title
      slug
    }
  }
`;

export const UPDATE_NOTE = `
  mutation UpdateNote($id: ID!, $input: NoteInput!) {
    update_note(id: $id, input: $input) {
      id
      title
      slug
    }
  }
`;
