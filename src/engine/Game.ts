import * as THREE from 'three';
import { SceneManager } from './SceneManager';
import { InputManager } from './InputManager';
import { TimeManager } from './TimeManager';
import { AssetManager } from './AssetManager';
import { AudioEngine } from './AudioEngine';

import { PlayerController } from '../player/PlayerController';
import { TerrainGenerator } from '../world/TerrainGenerator';
import { WaterPlane } from '../world/WaterPlane';
import { Vegetation } from '../world/Vegetation';
import { HUD } from '../ui/HUD';
import { Minimap } from '../ui/Minimap';
import { EnemyManager } from '../ai/EnemyManager';
import { DustSystem } from './DustSystem';
import { COLORS, CHUNK_WORLD_SIZE, RENDER_DISTANCE } from '../utils/constants';
import { worldToChunk } from '../utils/mathUtils';
import { BlueprintInterpreter } from '../world/BlueprintInterpreter';
import { LocationPlacer } from '../world/LocationPlacer';
import { MOCK_BLUEPRINT } from '../ai/mockBlueprint';
import { NPCManager } from '../ai/NPCManager';
import { DialogUI } from '../ui/DialogUI';

export class Game {
  private static _instance: Game;

  public sceneManager: SceneManager;
  public inputManager!: InputManager;
  public timeManager: TimeManager;
  public assetManager: AssetManager;
  public audioEngine!: AudioEngine;

  // Sistemas de juego
  public playerController!: PlayerController;
  public terrainGenerator!: TerrainGenerator;
  public vegetation!: Vegetation;
  public waterPlane!: WaterPlane;
  public hud!: HUD;
  public cloudsMesh!: THREE.InstancedMesh;
  public dustSystem!: DustSystem;

  // AI Content Engine
  public blueprintInterpreter!: BlueprintInterpreter;
  public locationPlacer!: LocationPlacer;
  public npcManager!: NPCManager;
  public enemyManager!: EnemyManager;
  public minimap!: Minimap;
  public dialogUI!: DialogUI;

  private constructor() {
    this.sceneManager = new SceneManager();
    this.timeManager = new TimeManager();
    this.assetManager = new AssetManager();
    this.audioEngine = new AudioEngine();
  }

  static get instance(): Game {
    if (!Game._instance) {
      Game._instance = new Game();
    }
    return Game._instance;
  }

  async init(): Promise<void> {
    const canvas = await this.sceneManager.init();
    this.inputManager = new InputManager(canvas);

    // Init Audio
    await this.audioEngine.init();
    await Promise.all([
      // this.audioEngine.loadSound('footstep', '/sounds/footstep.wav'),
      // this.audioEngine.loadSound('sword_swing', '/sounds/sword_swing.wav'),
      // this.audioEngine.loadSound('enemy_hit', '/sounds/enemy_hit.wav')
    ]);

    // --- AI Content Engine: interpret the region blueprint ---
    this.blueprintInterpreter = new BlueprintInterpreter(MOCK_BLUEPRINT);
    const terrainShaper = this.blueprintInterpreter.getTerrainShaper();
    console.log(`[AI Engine] Loaded Region: ${this.blueprintInterpreter.getRegionName()}`);
    console.log(this.blueprintInterpreter.getDescription());

    // Init AssetManager and Load Models
    this.assetManager = new AssetManager();
    try {
      await Promise.all([
        this.assetManager.loadModel('player', '/models/AnimatedKnight.gltf'),
        this.assetManager.loadModel('enemy', '/models/AnimatedEnemy.gltf'),
        this.assetManager.loadModel('villager', '/models/AnimatedVillager.gltf')
      ]);
    } catch (e) {
      console.error('[Game] Failed to load assets, proceeding anyway', e);
    }

    // Build villages/locations
    const scene = this.sceneManager.scene;
    this.locationPlacer = new LocationPlacer(scene, this.blueprintInterpreter);

    this.dialogUI = new DialogUI();
    this.npcManager = new NPCManager(
      scene,
      this.sceneManager.camera,
      this.blueprintInterpreter,
      this.locationPlacer
    );

    this.enemyManager = new EnemyManager(this.sceneManager.scene);
    this.enemyManager.init();

    console.log(`[AI] 🗺️  Region: "${this.blueprintInterpreter.getRegionName()}"`);
    console.log(`[AI] 📜  ${this.blueprintInterpreter.getDescription()}`);
    console.log(`[AI] 📍  Locations: ${this.blueprintInterpreter.getLocations().map(l => l.name).join(', ')}`);
    console.log(`[AI] 👤  NPCs: ${this.blueprintInterpreter.getNPCs().map(n => n.name).join(', ')}`);
    console.log(`[AI] ⚔️  Quests: ${this.blueprintInterpreter.getQuests().map(q => q.name).join(', ')}`);

    // Setup Environment (Task 7)
    scene.background = new THREE.Color(COLORS.SKY_BOTTOM);
    scene.fog = new THREE.FogExp2(COLORS.SKY_BOTTOM, 0.003);

    const dirLight = new THREE.DirectionalLight(COLORS.SUN, 2.0);
    dirLight.position.set(50, 100, 50);
    dirLight.castShadow = true;
    scene.add(dirLight);

    const ambientLight = new THREE.AmbientLight(0x6688cc, 0.4);
    scene.add(ambientLight);

    const hemiLight = new THREE.HemisphereLight(COLORS.SKY_BOTTOM, COLORS.GRASS_LOW, 0.3);
    scene.add(hemiLight);

    this.waterPlane = new WaterPlane();
    scene.add(this.waterPlane.mesh);

    this.dustSystem = new DustSystem(scene);

    // Setup Clouds
    const cloudCount = 150;
    const cloudGeo = new THREE.BoxGeometry(40, 10, 40);
    const cloudMat = new THREE.MeshLambertMaterial({ color: 0xffffff, transparent: true, opacity: 0.6 });
    this.cloudsMesh = new THREE.InstancedMesh(cloudGeo, cloudMat, cloudCount);
    const dummy = new THREE.Object3D();
    for (let i = 0; i < cloudCount; i++) {
      dummy.position.set(
        (Math.random() - 0.5) * 2000,
        150 + Math.random() * 50,
        (Math.random() - 0.5) * 2000
      );
      dummy.rotation.y = Math.random() * Math.PI;
      const s = 1 + Math.random() * 2;
      dummy.scale.set(s, s * 0.5, s);
      dummy.updateMatrix();
      this.cloudsMesh.setMatrixAt(i, dummy.matrix);
    }
    scene.add(this.cloudsMesh);

    // Setup Systems — pass the AI terrain shaper to the terrain generator
    this.terrainGenerator = new TerrainGenerator(scene, terrainShaper);
    this.vegetation = new Vegetation(scene, terrainShaper);
    this.playerController = new PlayerController(
      scene,
      this.inputManager,
      this.terrainGenerator,
      this.sceneManager.camera
    );
    this.hud = new HUD();

    // Fuerza una actualización inicial para evitar que la cámara o el jugador se rendericen en (0,0,0) un instante
    this.playerController.update(0.016);

    // Loop
    this.sceneManager.renderer.setAnimationLoop(this.gameLoop.bind(this));
    console.log('[Game] Fabled Kingdoms initialized');
  }

  private gameLoop(): void {
    this.timeManager.update();
    const dt = this.timeManager.deltaTime;

    this.playerController.update(dt);
    this.terrainGenerator.update(this.playerController.position.x, this.playerController.position.z);
    
    // NPCs
    if (this.npcManager) {
      this.npcManager.update(dt, this.playerController.position, this.timeManager.elapsedTime, this.terrainGenerator);
    }
    if (this.enemyManager) {
      this.enemyManager.update(dt, this.timeManager.elapsedTime, this.playerController.position, this.terrainGenerator);
    }

    // Dialog Interaction
    if (this.inputManager.isKeyDown('KeyE')) {
      if (!this.dialogUI.isOpen && this.npcManager.nearestNPC) {
        const npc = this.npcManager.nearestNPC.data;
        this.dialogUI.show(npc.name, npc.role, npc.greeting);
      }
    } else {
      // Hide if E is released and player moves away?
      // For now, E shows it, if we move away it hides
      if (this.dialogUI.isOpen && !this.npcManager.nearestNPC) {
        this.dialogUI.hide();
      }
    }

    // Generar vegetación en los chunks activos
    const activeVegetationKeys = new Set<string>();
    const { cx, cz } = worldToChunk(this.playerController.position.x, this.playerController.position.z, CHUNK_WORLD_SIZE);
    for (let x = -RENDER_DISTANCE; x <= RENDER_DISTANCE; x++) {
      for (let z = -RENDER_DISTANCE; z <= RENDER_DISTANCE; z++) {
        const targetCx = cx + x;
        const targetCz = cz + z;
        this.vegetation.generateForChunk(targetCx, targetCz);
        activeVegetationKeys.add(`${targetCx},${targetCz}`);
      }
    }
    this.vegetation.cleanupChunks(activeVegetationKeys);

    // Update systems
    this.dustSystem.update(dt);
    this.waterPlane.update(this.playerController.position.x, this.playerController.position.z);

    // Animate clouds
    if (this.cloudsMesh) {
      this.cloudsMesh.position.x = this.playerController.position.x + Math.sin(this.timeManager.elapsedTime * 0.05) * 500;
      this.cloudsMesh.position.z = this.playerController.position.z + Math.cos(this.timeManager.elapsedTime * 0.05) * 500;
    }

    const terrainShaper = this.blueprintInterpreter.getTerrainShaper();
    this.hud.update(dt, this.timeManager.elapsedTime, this.playerController.position, terrainShaper);

    this.sceneManager.render();
  }
}
