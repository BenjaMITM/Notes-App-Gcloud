<script lang="ts">
  import { createEventDispatcher, onDestroy } from 'svelte';
  import { forceSimulation, forceManyBody, forceCollide, forceLink, forceX, forceY } from 'd3-force';
  import type { BrainView, GraphLink, GraphNode } from '$lib/types';

  export let view: BrainView | null = null;
  export let selectedId: string | null = null;

  const dispatch = createEventDispatcher();
  let nodes: GraphNode[] = [];
  let links: GraphLink[] = [];
  let simulation: ReturnType<typeof forceSimulation> | null = null;

  const anchors = {
    focus: { x: 0, y: 0 },
    parent: { x: -180, y: -160 },
    child: { x: -180, y: 160 },
    sibling: { x: 210, y: 0 }
  } as const;

  $: if (view) {
    buildGraph(view);
  } else {
    nodes = [];
    links = [];
    simulation?.stop();
  }

  $: nodeMap = new Map(nodes.map((node) => [node.id, node]));

  function buildGraph(view: BrainView) {
    const focus: GraphNode = {
      id: view.focus.id,
      title: view.focus.title,
      group: 'focus',
      x: anchors.focus.x,
      y: anchors.focus.y
    };

    const parentNodes = view.parents.map((note) => ({
      id: note.id,
      title: note.title,
      group: 'parent' as const
    }));

    const childNodes = view.children.map((note) => ({
      id: note.id,
      title: note.title,
      group: 'child' as const
    }));

    const siblingNodes = view.siblings.map((note) => ({
      id: note.id,
      title: note.title,
      group: 'sibling' as const
    }));

    nodes = [focus, ...parentNodes, ...childNodes, ...siblingNodes];

    links = [
      ...parentNodes.map((node) => ({ source: node.id, target: focus.id, kind: 'parent' as const })),
      ...childNodes.map((node) => ({ source: focus.id, target: node.id, kind: 'child' as const })),
      ...siblingNodes.map((node) => ({ source: focus.id, target: node.id, kind: 'sibling' as const }))
    ];

    startSimulation();
  }

  function startSimulation() {
    simulation?.stop();

    simulation = forceSimulation(nodes)
      .force('charge', forceManyBody().strength(-260))
      .force('collide', forceCollide(36))
      .force(
        'x',
        forceX<GraphNode>((node) => anchors[node.group].x).strength(0.55)
      )
      .force(
        'y',
        forceY<GraphNode>((node) => anchors[node.group].y).strength(0.6)
      )
      .force(
        'link',
        forceLink<GraphNode, GraphLink>(links)
          .id((node) => node.id)
          .distance(140)
          .strength(0.7)
      )
      .alpha(1)
      .restart();

    simulation.on('tick', () => {
      nodes = [...nodes];
    });
  }

  function displayTitle(title: string) {
    return title.length > 18 ? `${title.slice(0, 16)}…` : title;
  }

  function resolveNode(value: string | GraphNode | undefined) {
    if (!value) return undefined;
    if (typeof value === 'string') return nodeMap.get(value);
    return value;
  }

  function handleSelect(node: GraphNode) {
    dispatch('select', { id: node.id });
  }

  onDestroy(() => {
    simulation?.stop();
  });
</script>

{#if view}
  <svg viewBox="-380 -260 760 520" preserveAspectRatio="xMidYMid meet">
    <g class="rings">
      <circle cx="0" cy="0" r="110" fill="none" stroke="rgba(255,255,255,0.06)" stroke-dasharray="6 8" />
      <circle cx="0" cy="0" r="210" fill="none" stroke="rgba(255,255,255,0.04)" stroke-dasharray="3 10" />
    </g>

    {#each links as link (String(link.source) + String(link.target) + link.kind)}
      {#if resolveNode(link.source) && resolveNode(link.target)}
        <line
          class="link {link.kind}"
          x1={resolveNode(link.source)?.x}
          y1={resolveNode(link.source)?.y}
          x2={resolveNode(link.target)?.x}
          y2={resolveNode(link.target)?.y}
        />
      {/if}
    {/each}

    {#each nodes as node (node.id)}
      <g
        class="node {node.group} {selectedId === node.id ? 'active' : ''}"
        transform={`translate(${node.x ?? 0}, ${node.y ?? 0})`}
        on:click={() => handleSelect(node)}
        role="button"
        tabindex="0"
      >
        <circle r={node.group === 'focus' ? 36 : 26} />
        <text y="5" text-anchor="middle">{displayTitle(node.title)}</text>
      </g>
    {/each}
  </svg>
{:else}
  <div class="graph-empty">Select a note to see the brain view.</div>
{/if}

<style>
  .link {
    stroke: rgba(255, 255, 255, 0.25);
    stroke-width: 2;
  }

  .link.parent {
    stroke: rgba(196, 91, 42, 0.6);
  }

  .link.child {
    stroke: rgba(46, 91, 124, 0.7);
  }

  .link.sibling {
    stroke: rgba(255, 255, 255, 0.4);
  }

  .node {
    cursor: pointer;
  }

  .node circle {
    fill: rgba(255, 255, 255, 0.1);
    stroke: rgba(255, 255, 255, 0.4);
    stroke-width: 1.4;
  }

  .node.focus circle {
    fill: rgba(196, 91, 42, 0.32);
    stroke: rgba(196, 91, 42, 0.9);
  }

  .node.parent circle {
    fill: rgba(196, 91, 42, 0.18);
  }

  .node.child circle {
    fill: rgba(46, 91, 124, 0.28);
  }

  .node.sibling circle {
    fill: rgba(255, 255, 255, 0.12);
  }

  .node text {
    fill: rgba(248, 246, 240, 0.95);
    font-size: 12px;
    pointer-events: none;
  }

  .node.active circle {
    stroke: #f6f3ee;
    stroke-width: 2.4;
  }

  .graph-empty {
    color: rgba(248, 246, 240, 0.8);
    padding: 16px;
    font-size: 0.95rem;
  }
</style>
