export type NoteSummary = {
  id: string;
  title: string;
  slug: string;
};

export type NoteLink = {
  id: string;
  kind: string;
  label: string;
  url?: string | null;
  from_id: string;
  to_id?: string | null;
  to_note?: NoteSummary | null;
  from_note?: NoteSummary | null;
};

export type Note = NoteSummary & {
  body: string;
  tags: string[];
  mentions: string[];
  incoming_links: NoteLink[];
  outgoing_links: NoteLink[];
  updated_at: string;
};

export type BrainView = {
  focus: NoteSummary;
  parents: NoteSummary[];
  children: NoteSummary[];
  siblings: NoteSummary[];
};

export type GraphNode = {
  id: string;
  title: string;
  group: 'focus' | 'parent' | 'child' | 'sibling';
  x?: number;
  y?: number;
};

export type GraphLink = {
  source: string | GraphNode;
  target: string | GraphNode;
  kind: 'parent' | 'child' | 'sibling';
};
