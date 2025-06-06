---
layout: post
title: Experimenting with MCP - Building an Evergreen Knowledge Server for WoW Specs
categories: [AI, Gaming, MCP]
excerpt: Learn how to build a Model Context Protocol (MCP) server that provides real-time knowledge about various World of Warcraft specializations, connecting LLMs like Claude to current game information.
---

## Introduction: What is MCP?

The **Model Context Protocol (MCP)** is an open protocol that lets you build servers which provide context, tools, and resources to Large Language Models (LLMs) like Claude or ChatGPT. It enables connecting custom knowledge, workflows, and data to AI assistants in real-time.

### Key Benefits of MCP
- **Live Knowledge:** MCP lets you connect LLMs to real-time, up-to-date data and tools, not just static training data.
- **Composable:** You can add new tools, resources, or prompts for various domains including games, business, and research.
- **Separation of Concerns:** The LLM focuses on reasoning and synthesis, while your MCP server handles data fetching, business logic, or integration with external systems.
- **Open and Extensible:** Anyone can build and run their own MCP server, and any LLM client that supports MCP can use it.

This makes MCP perfect for things like:
- Game knowledge bots (like our WoW specializations server)
- Custom data dashboards
- Workflow automation
- Integrating LLMs with private or proprietary data

---

## The Project: An Evergreen WoW Specs Knowledge Server

### What We Built
- **A Node.js MCP server** using the [mcp-framework](https://github.com/QuantGeekDev/mcp-framework)
- **A custom tool** that fetches live, up-to-date information about various WoW specializations from top WoW sites (Murlok.io, Wowhead, Icy Veins, Method)
- **Integration with Claude Desktop** so the LLM can call the tool and synthesize answers for any WoW spec question

### How It Works
1. **User asks a question** (e.g., "What are the best stats for Vengeance Demon Hunter in Mythic+?")
2. **The MCP tool matches the question** to relevant topics and URLs using a pre-built resource index
3. **It fetches and parses live data** from the best sources (ensuring up-to-date information)
4. **Returns the extracted info** (with source links) to the LLM, which combines and presents the answer

---

## Example: Stat Weights from Murlok.io

**User Input:**
```
What are the stat weights for Vengeance Demon Hunter in Mythic+?
```

**MCP Tool Output:**
```json
{
  "question": "What are the stat weights for Vengeance Demon Hunter in Mythic+?",
  "sources": [
    {
      "url": "https://murlok.io/demon-hunter/vengeance/mm+",
      "content": "Secondary Stats\nHaste - 32% (2129 rating)\nCritical Strike - 33% (1591 rating)\nVersatility - 7% (558 rating)\nMastery - 29% (453 rating)\nMinor Stats\nLeech - 13% (328 rating)\nAvoidance - 1% (415 rating)\nSpeed - 2% (0 rating)"
    }
  ]
}
```

**LLM Synthesized Answer:**
> The current stat priority for Vengeance Demon Hunter in Mythic+ (from Murlok.io, top 50 players, Patch 11.1) is:
> - Haste: 32%
> - Critical Strike: 33%
> - Versatility: 7%
> - Mastery: 29%
> - Leech: 13% (minor stat)
> - Avoidance: 1% (minor stat)
> - Speed: 2% (minor stat)
>
> Data is refreshed every 8 hours and reflects what top players are actually using.

---

## More Example Inputs and Outputs

### Example 2: Talents for Raiding

**User Input:**
```
What are the best talents for Vengeance Demon Hunter in raids?
```

**MCP Tool Output:**
```json
{
  "question": "What are the best talents for Vengeance Demon Hunter in raids?",
  "sources": [
    {
      "url": "https://www.method.gg/guides/vengeance-demon-hunter/talents",
      "content": "Talent Builds\nFel-Scarred - Single Target/Cleave\nAldrachi - Single Target\nFel Scarred Cleave\nAldrachi Reaver - Cleave\nAldrachi Reaver - Mythic+\nFel-Scarred - Mythic+\nClass Talents\nSpec Talents\nHero Talents\nAldrachi Reaver\nFel-Scarred"
    }
  ]
}
```

**LLM Synthesized Answer:**
> For raiding as a Vengeance Demon Hunter, top talent builds include Fel-Scarred for single target/cleave and Aldrachi Reaver for single target. See Method.gg for full builds and explanations.

---

### Example 3: Consumables and Enchants

**User Input:**
```
What consumables and enchants should I use as a Vengeance Demon Hunter tank?
```

**MCP Tool Output:**
```json
{
  "question": "What consumables and enchants should I use as a Vengeance Demon Hunter tank?",
  "sources": [
    {
      "url": "https://www.icy-veins.com/wow/vengeance-demon-hunter-pve-tank-gems-enchants-consumables",
      "content": "Best Enchants for Vengeance Demon Hunter\nBest Gems for Vengeance Demon Hunter in The War Within\nBest Flask for Vengeance Demon Hunter in The War Within\nBest Weapon Oil/Stone for Vengeance Demon Hunter in The War Within\nBest Potion for Vengeance Demon Hunter in The War Within\nBest Food for Vengeance Demon Hunter in The War Within"
    }
  ]
}
```

**LLM Synthesized Answer:**
> For consumables and enchants, use the best gems, flasks, weapon oils, potions, and food as recommended by Icy Veins for the current patch. Always check for the latest updates!

---

## How We Built It

1. **Compiled a list of trusted URLs** for VDH guides and stats:

```javascript
// From src/tools/vdh_resources_scraper.js
const URLS = [
  "https://murlok.io/demon-hunter/vengeance/mm+",
  "https://www.wowhead.com/guide/classes/demon-hunter/vengeance/war-within-season-2",
  "https://www.method.gg/guides/vengeance-demon-hunter/talents",
  "https://www.icy-veins.com/wow/vengeance-demon-hunter-pve-tank-guide",
  // ... many more URLs
];
```

2. **Created a scraper** to build a resource index with headings from each site:

```javascript
// From src/tools/vdh_resources_scraper.js
async function fetchAndExtract(url) {
  try {
    const { data } = await axios.get(url);
    const $ = cheerio.load(data);
    // Extract main headings and subheadings
    const headings = [];
    $("h1, h2, h3").each((_, el) => {
      headings.push({
        tag: el.tagName,
        text: $(el).text().trim()
      });
    });
    return { url, headings };
  } catch (e) {
    return { url, error: e.message };
  }
}

// Run the scraper
(async () => {
  const results = [];
  for (const url of URLS) {
    console.log(`Fetching: ${url}`);
    const result = await fetchAndExtract(url);
    results.push(result);
  }
  fs.writeFileSync("vdh_resources_index.json", JSON.stringify(results, null, 2));
  console.log("Done. Results written to vdh_resources_index.json");
})();
```

3. **Wrote a Node.js MCP tool** that:
    - Loads the resource index with topics/headings from each site
    - Matches user questions to relevant topics/URLs
    - Fetches and parses the live HTML using `axios` and `cheerio`
    - Extracts the most relevant section for the question
    - Returns the info and source links to the LLM

```typescript
// From src/tools/VengeanceDemonHunterTool.ts
import { MCPTool } from "mcp-framework";
import { z } from "zod";
import axios from "axios";
import * as cheerio from "cheerio";
import fs from "fs";

// Simple keyword-to-topic mapping
const TOPIC_KEYWORDS: Record<string, string[]> = {
  "rotation": ["rotation", "playstyle", "opener", "cooldown"],
  "talents": ["talent", "build", "spec"],
  "stats": ["stat", "priority"],
  "consumables": ["consumable", "flask", "food", "potion", "enchant", "gem"],
  "mythic+": ["mythic+", "m+", "dungeon"],
  "raid": ["raid", "boss", "undermine"],
  // ... more topics
};

// Find relevant resources based on question keywords
function findRelevantResources(question: string): string[] {
  const lowerQ = question.toLowerCase();
  // Find all topics that match the question
  const matchedTopics = Object.entries(TOPIC_KEYWORDS)
    .filter(([topic, keywords]) => keywords.some(k => lowerQ.includes(k)))
    .map(([topic]) => topic);

  // Find resources whose headings or URL match any topic
  const relevant = RESOURCE_INDEX.filter(resource => {
    if (resource.error) return false;
    if (matchedTopics.some(topic => resource.url.toLowerCase().includes(topic))) return true;
    if (resource.headings && resource.headings.some(h => 
        matchedTopics.some(topic => h.text.toLowerCase().includes(topic)))) return true;
    return false;
  });

  return relevant.map(r => r.url);
}

// The main tool class
class VengeanceDemonHunterTool extends MCPTool<VengeanceDemonHunterInput> {
  name = "vengeance_demon_hunter";
  description = "Answers any questions about Vengeance Demon Hunter in World of Warcraft.";

  schema = {
    question: {
      type: z.string(),
      description: "A question about Vengeance Demon Hunter",
    },
  };

  async execute(input: VengeanceDemonHunterInput) {
    const question = input.question;
    // 1. Find relevant resources
    const urls = findRelevantResources(question);
    // 2. Fetch and extract relevant sections (limit to 5 for performance)
    const fetches = urls.slice(0, 5).map(url => fetchRelevantSections(url, question));
    const results = await Promise.all(fetches);
    // 3. Format the output for the LLM
    return {
      question,
      sources: results.map(r => ({ url: r.url, content: r.content }))
    };
  }
}

// Register the tool with the MCP framework
new VengeanceDemonHunterTool();
```

4. **Set up the MCP server** with a simple entry point:

```typescript
// From src/index.ts
import { MCPServer } from "mcp-framework";
import "./tools/VengeanceDemonHunterTool.js";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

// Get package info for server metadata
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const pkg = JSON.parse(readFileSync(join(__dirname, "../package.json"), "utf-8"));

// Create and start the MCP server
const server = new MCPServer({
  name: pkg.name,
  version: pkg.version,
  transport: {
    type: "sse",
    options: {
      port: 1337,
      cors: {
        allowOrigin: "*"
      }
    }
  }
});

server.start();
```

5. **Integrated with Claude Desktop** by adding this to `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "wow-vdh": {
      "command": "node",
      "args": ["C:/Users/bashby/projects/mcp/wow-mcp/dist/index.js"]
    }
  }
}
```

---

## Key Advantages
- **Always up-to-date:** Retrieves current data directly from authoritative sources
- **Multi-source:** Combines info from Wowhead, Icy Veins, Method, Murlok.io, and more
- **Single point of access:** Users can ask a single question to a single source (the AI) which scrapes answers from various sources and combines them to create the best comprehensive answer
- **LLM-ready:** Returns structured, source-linked data for the LLM to synthesize
- **Composable:** You can add additional tools, resources, or prompts for various games, topics, or workflows

---

## Key Takeaways
- MCP effectively extends LLMs with custom, real-time knowledge sources
- Node.js with appropriate libraries provides an efficient framework for fetching and parsing web data
- The architecture leverages LLMs for synthesis while focusing development efforts on providing quality data

---

## Want to Try It?

Want to build your own WoW knowledge server or adapt this for another game or domain? Here's how to get started:

### 1. Set up your project

```bash
# Create a new directory for your project
mkdir wow-mcp-server
cd wow-mcp-server

# Initialize a new Node.js project
npm init -y

# Install dependencies
npm install mcp-framework axios cheerio zod
npm install -D typescript @types/node

# Initialize TypeScript
npx tsc --init
```

### 2. Create your MCP server

Create `src/index.ts`:

```typescript
import { MCPServer } from "mcp-framework";
import "./tools/WoWSpecTool.js";

const server = new MCPServer({
  name: "wow-spec-knowledge-server",
  version: "1.0.0",
  transport: {
    type: "sse",
    options: {
      port: 1337,
      cors: {
        allowOrigin: "*"
      }
    }
  }
});

server.start();
```

### 3. Create your custom tool

Create `src/tools/WoWSpecTool.ts`:

```typescript
import { MCPTool } from "mcp-framework";
import { z } from "zod";
import axios from "axios";
import * as cheerio from "cheerio";

// Define your tool's input interface
interface WoWSpecInput {
  question: string;
  spec?: string;  // Optional spec parameter
}

class WoWSpecTool extends MCPTool<WoWSpecInput> {
  name = "wow_spec_knowledge";
  description = "Answers questions about World of Warcraft specializations";

  schema = {
    question: {
      type: z.string(),
      description: "A question about a WoW specialization",
    },
    spec: {
      type: z.string().optional(),
      description: "Optional: The specific specialization (e.g., 'Vengeance Demon Hunter')",
    },
  };

  async execute(input: WoWSpecInput) {
    // Your implementation here
    // 1. Find relevant resources
    // 2. Fetch and extract content
    // 3. Return formatted results

    return {
      question: input.question,
      sources: [
        {
          url: "https://example.com/wow-guide",
          content: "Example content about the spec"
        }
      ]
    };
  }
}

// Register the tool
new WoWSpecTool();
```

### 4. Connect to Claude Desktop

Add this to your Claude Desktop configuration:

```json
{
  "mcpServers": {
    "wow-spec": {
      "command": "node",
      "args": ["path/to/your/dist/index.js"]
    }
  }
}
```

### 5. Build and run your server

```bash
# Compile TypeScript
npx tsc

# Run your server
node dist/index.js
```

For a complete implementation, check out my [wow-mcp repository](https://github.com/benashby/wow-mcp) which includes the full Vengeance Demon Hunter tool with resource scraping, keyword matching, and content extraction.

---

*For more information on MCP, visit the resources linked above.*
