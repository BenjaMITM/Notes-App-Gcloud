<script lang="ts">
  import { onMount } from 'svelte';
  import BrainGraph from '$lib/components/BrainGraph.svelte';
  import { gqlFetch } from '$lib/graphql';
  import { BRAIN_QUERY, CREATE_NOTE, NOTE_QUERY, NOTES_QUERY, UPDATE_NOTE } from '$lib/queries';
  import type { BrainView, Note, NoteSummary } from '$lib/types';
  import MarkdownIt from 'markdown-it';

  let notes: NoteSummary[] = [];
  let selectedId: string | null = null;
  let selectedNote: Note | null = null;
  let brain: BrainView | null = null;
  let loading = false;
  let error = '';
  let search = '';

  let editTitle = '';
  let editBody = '';

  let newTitle = '';
  let newBody = '';
  let creating = false;
  let saving = false;

  const formatter = new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium'
  });

  const md = new MarkdownIt({
    html: false,
    linkify: true,
    breaks: true
  });

  $: previewHtml = md.render(editBody || '');

  $: dirty =
    selectedNote !== null &&
    (editTitle !== selectedNote.title || editBody !== selectedNote.body);

  $: selectedUpdatedAt = selectedNote?.updated_at
    ? formatter.format(new Date(selectedNote.updated_at))
    : null;

  let searchTimer: ReturnType<typeof setTimeout> | null = null;

  onMount(() => {
    loadNotes();
  });

  async function loadNotes() {
    loading = true;
    error = '';

    try {
      const data = await gqlFetch(NOTES_QUERY, {
        limit: 100,
        search: search.trim() || null
      });
      notes = data.notes;

      if (selectedId && !notes.some((note) => note.id === selectedId)) {
        selectedId = null;
      }

      if (!selectedId && notes.length > 0) {
        await selectNote(notes[0].id);
      }
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to load notes.';
    } finally {
      loading = false;
    }
  }

  async function selectNote(id: string) {
    loading = true;
    error = '';
    selectedId = id;

    try {
      const [noteData, brainData] = await Promise.all([
        gqlFetch(NOTE_QUERY, { id }),
        gqlFetch(BRAIN_QUERY, { id, related_limit: 12 })
      ]);

      selectedNote = noteData.note;
      brain = brainData.brain_view;

      if (selectedNote) {
        editTitle = selectedNote.title;
        editBody = selectedNote.body;
      }
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to load note.';
    } finally {
      loading = false;
    }
  }

  async function createNote() {
    if (!newTitle.trim() || !newBody.trim()) {
      error = 'Title and body are required.';
      return;
    }

    creating = true;
    error = '';

    try {
      const data = await gqlFetch(CREATE_NOTE, {
        input: {
          title: newTitle.trim(),
          body: newBody.trim()
        }
      });

      newTitle = '';
      newBody = '';

      if (data.create_note) {
        await loadNotes();
        await selectNote(data.create_note.id);
      }
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to create note.';
    } finally {
      creating = false;
    }
  }

  async function saveNote() {
    if (!selectedId || !selectedNote) return;
    if (!editTitle.trim() || !editBody.trim()) {
      error = 'Title and body are required.';
      return;
    }

    saving = true;
    error = '';

    try {
      await gqlFetch(UPDATE_NOTE, {
        id: selectedId,
        input: {
          title: editTitle.trim(),
          body: editBody.trim()
        }
      });

      await loadNotes();
      await selectNote(selectedId);
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to save note.';
    } finally {
      saving = false;
    }
  }

  function handleSearchInput() {
    if (searchTimer) clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      loadNotes();
    }, 250);
  }
</script>

<div class="app">
  <section class="panel">
    <header>
      <h2>Notes</h2>
      <small>{notes.length} total</small>
    </header>

    <div class="field">
      <label for="search">Search</label>
      <input id="search" type="text" bind:value={search} on:input={handleSearchInput} />
    </div>

    <div class="field">
      <label for="new-title">New note title</label>
      <input id="new-title" type="text" bind:value={newTitle} />
    </div>

    <div class="field">
      <label for="new-body">New note body</label>
      <textarea id="new-body" bind:value={newBody}></textarea>
    </div>

    <button class="button" on:click={createNote} disabled={creating}>
      {creating ? 'Creating...' : 'Create note'}
    </button>

    <div class="note-list">
      {#if loading}
        <small>Loading notes...</small>
      {:else if notes.length === 0}
        <small>No notes yet.</small>
      {:else}
        {#each notes as note}
          <div
            class={`note-item ${note.id === selectedId ? 'active' : ''}`}
            on:click={() => selectNote(note.id)}
          >
            <h3>{note.title}</h3>
            <span>{note.slug}</span>
          </div>
        {/each}
      {/if}
    </div>
  </section>

  <section class="panel">
    <header>
      <h2>Editor</h2>
      {#if selectedUpdatedAt}
        <small>Updated {selectedUpdatedAt}</small>
      {/if}
    </header>

    {#if selectedNote}
      <div class="field">
        <input class="editor-title" type="text" bind:value={editTitle} />
      </div>

      <div class="field">
        <label for="note-body">Markdown</label>
        <textarea id="note-body" bind:value={editBody}></textarea>
      </div>

      <div class="field">
        <label>Preview</label>
        <div class="preview">
          {@html previewHtml}
        </div>
      </div>

      <div class="meta-row">
        {#each selectedNote.tags as tag}
          <span class="tag">#{tag}</span>
        {/each}
        {#each selectedNote.mentions as mention}
          <span class="link-chip">@{mention}</span>
        {/each}
      </div>

      <div class="meta-row">
        <button class="button" disabled={!dirty || saving} on:click={saveNote}>
          {saving ? 'Saving...' : 'Save changes'}
        </button>
        <small>{dirty ? 'Unsaved changes' : 'All changes saved'}</small>
      </div>
    {:else}
      <small>Select a note to start editing.</small>
    {/if}

    {#if error}
      <small>{error}</small>
    {/if}
  </section>

  <section class="panel">
    <header>
      <h2>Brain View</h2>
      <small>Parents, children, siblings</small>
    </header>

    <div class="graph-shell">
      <BrainGraph view={brain} selectedId={selectedId} on:select={(event) => selectNote(event.detail.id)} />
    </div>

    {#if selectedNote}
      <div>
        <h3>Backlinks</h3>
        <div class="note-list">
          {#if selectedNote.incoming_links.length === 0}
            <small>No backlinks yet.</small>
          {:else}
            {#each selectedNote.incoming_links as link}
              <div class="backlink-item" on:click={() => link.from_note && selectNote(link.from_note.id)}>
                <strong>{link.from_note?.title ?? link.label}</strong>
                <small>{link.kind}</small>
              </div>
            {/each}
          {/if}
        </div>
      </div>
    {/if}
  </section>
</div>
