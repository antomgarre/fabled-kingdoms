import { IAIFloraDefinition } from '../world/ProceduralMeshBuilder';

export class AIObjectGenerator {
  private static MOCK_RESPONSE: IAIFloraDefinition[] = [
    {
      species_id: "roble_ancestral",
      name: "Roble Ancestral de Farewell",
      description: "Un árbol corpulento con hojas de un verde profundo.",
      trunk: { base_radius: 0.4, top_radius: 0.25, height: 2.5, color: "#4A2F1D" },
      leaves: { shape: "sphere", radius: 2.5, height: 2.5, color: "#2D5A27", y_offset: 3.0 },
      density_multiplier: 1.0
    },
    {
      species_id: "sauce_lloron",
      name: "Sauce Dorado",
      description: "Hojas amarillentas que caen como lágrimas.",
      trunk: { base_radius: 0.2, top_radius: 0.15, height: 3.0, color: "#5C4A3D" },
      leaves: { shape: "cone", radius: 1.5, height: 4.0, color: "#8A9A3B", y_offset: 3.5 },
      density_multiplier: 0.5
    },
    {
      species_id: "arbusto_azul",
      name: "Zarza Lunar",
      description: "Pequeño arbusto de tonos azulados.",
      trunk: { base_radius: 0.05, top_radius: 0.05, height: 0.2, color: "#222222" },
      leaves: { shape: "sphere", radius: 0.8, height: 0.8, color: "#3B5A7A", y_offset: 0.5 },
      density_multiplier: 1.5
    }
  ];

  static async generateFloraForRegion(regionDescription: string): Promise<IAIFloraDefinition[]> {
    // Aquí iría la llamada fetch a Gemini usando GEMINI_API_KEY.
    // fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${import.meta.env.VITE_GEMINI_API_KEY}`)
    // Como las llamadas de red pueden fallar o demorar en el prototipo local de Vite 
    // sin un backend configurado, devolvemos el mock generado por IA para demostrar la capacidad:
    
    console.log(`[AI Generator] Generando flora para región: ${regionDescription.substring(0, 30)}...`);
    
    return new Promise((resolve) => {
      setTimeout(() => resolve(this.MOCK_RESPONSE), 500); // Simulate API latency
    });
  }
}
