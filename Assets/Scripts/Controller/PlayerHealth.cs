using UnityEngine.Events;
using UnityEngine;
using RootMotion.Dynamics;
using StarterAssets;
using UnityEngine.InputSystem;
using UnityEngine.Rendering;
using System.Linq;
using UnityEngine.VFX;


namespace DesirePaths {
public class PlayerHealth : MonoBehaviour {
  public PlayerDeathEvent PlayerDeathEvent;
  public UnityEvent m_OnCharacterDeath;
  private bool dead;
  private bool safe;
  public ThirdPersonController _thirdPersonController;
  public CharacterController _characterController;
  public PlayerInput _playerInputs;
  public Transform t_checkLayerTransform;
  [Header("UI/UX Feedbacks")]
  public bool allowColorChange = true;
  public ParticleSystem _groundHealPS;
  public PuppetMaster _puppetMaster;
  public Animator _controllerAnimator;
  public SkinnedMeshRenderer _organsRenderer;
  public SkinnedMeshRenderer _bodyRenderer;
  public Light _light;
  public Volume _dangerVolume;
  public AnimationCurve _dangerAnimationCurve;

  [Header("Options")]
  public AnimationCurve _healthLossCurve;
  public AnimationCurve _healthGainCurve; // Not used currently, we'll see
  public Gradient _healthLossGradient;
  public Gradient _bodyGradient;
  [Header("LightOptions")]
  public float maxLightValue = 1f;
  public float minLightValue = 0.1f;
  public AnimationCurve
      lightOscillationAmplitudeCurve; // This is done according to sin(x) where
                                      // x evolves by Time.deltaTime
  [Header("Duration & Mask")]
  public float maxHealthValue = 10f; // Max 10 seconds currently
  [SerializeField]
  private float _currentHealthValue;
  [Header("Vitesse (interpolation par AnimationCurve)")]
 [Tooltip("Définit l'interpolation entre MoveSpeed (à 0 vie) et SprintSpeed normal (à vie max). L'axe X doit être entre 0 et 1.")]
  public AnimationCurve speedCurve = AnimationCurve.Linear(0, 0, 1, 1);


  private float currentOscillationModifier;
  private float currentOscillationDuration;
  private float _originalLightRange;
  [Tooltip("Player game object, should probably be MediumRetopoRigged")]
  public GameObject player;

  [Tooltip(
      "Struggle map writable texture used elsewhere, for example in the terrain shader to change ground color based on walked paths")]
  public Texture2D struggle_map;
  public Vector3 respawn_position;

 // Vitesse de base stockées lors du démarrage
  private float normalSprintSpeed;
  private float normalMoveSpeed;
    
  // Toggles pour immortal (touche I)
  private bool healthToggleActivated = false; 
  private bool speedMultiplierActivated = false;

  //public VisualEffect vfxDamages;



  void Awake() {
    
   InitializeValues();

   if (_thirdPersonController != null) {
            normalSprintSpeed = _thirdPersonController.SprintSpeed;
            normalMoveSpeed = _thirdPersonController.MoveSpeed;
   }
  
  }

  private void InitializeValues() {
    if (m_OnCharacterDeath == null)
      m_OnCharacterDeath = new UnityEvent();
    safe = true;
    dead = false;
    _currentHealthValue = maxHealthValue;
    _groundHealPS.Stop();
    _originalLightRange = _light.range;
    respawn_position = player.transform.position;

     if(_thirdPersonController != null)
        normalSprintSpeed = _thirdPersonController.SprintSpeed;
  }
  

  void Update() { 

    if (Keyboard.current != null && Keyboard.current.gKey.wasPressedThisFrame) {
        healthToggleActivated = !healthToggleActivated;
        //speedMultiplierActivated = !speedMultiplierActivated;
        Debug.Log("Health toggle " + (healthToggleActivated ? "activé" : "désactivé"));
        // Si activé, on force immédiatement la vie à max
        if (healthToggleActivated) {
            _currentHealthValue = maxHealthValue;
            
        }
    }

    if (Keyboard.current != null && Keyboard.current.fKey.wasPressedThisFrame) {
        speedMultiplierActivated = !speedMultiplierActivated;        
    }
    
    CheckSafe();
    UpdateMovementSpeed();
  }

  private void LateUpdate() {
    UpdateAnimator();
    UpdateOscillation();
  }

  void OnGUI() {
    if (healthToggleActivated) {
        // Affiche "GOD DEBUG MODE" en haut à gauche de l'écran
        GUI.Label(new Rect(10, 30, 200, 20), "GOD DEBUG MODE");
    }

    if (speedMultiplierActivated) {
        // Affiche "GOD DEBUG MODE" en haut à gauche de l'écran
        GUI.Label(new Rect(10, 50, 200, 20), "FASTASFUCK DEBUG MODE");
    }

  }

  private void CheckSafe() {

    if (healthToggleActivated) {
        _currentHealthValue = maxHealthValue;
        UpdateLifeVisuals(1f); // 1 correspond à 100% de vie
        return;
    }


    RaycastHit[] hits =
        Physics.RaycastAll(player.transform.position + 3 * Vector3.up,
                           Vector3.down, Mathf.Infinity);
    bool walking_over_safe_object =
        hits.Any(hit => hit.collider.CompareTag("Safe"));
    (int u, int v) = GetStruggleUV();
    Color pixel = struggle_map.GetPixel(u, v);
    bool walking_on_walked = pixel.g > .5f;
    safe = walking_over_safe_object || walking_on_walked;

    if (safe) {
      // add health
      _currentHealthValue += Time.deltaTime;
      if (_currentHealthValue >= maxHealthValue)
        _currentHealthValue = maxHealthValue;

      // show safe visuals
      if (walking_over_safe_object) {
        // idk why but this does nothing
        // // Place particle system
        // var particleTransform = _groundHealPS.transform;
        // particleTransform.localPosition =
        //     particleTransform.InverseTransformPoint(
        //         _hit.point); // To get correct height
        // particleTransform.localRotation.SetLookRotation(_hit.normal);
      }
      if (!_groundHealPS.isPlaying)
        _groundHealPS.Play();
    } else {
      // lose heatlh
      _currentHealthValue -= Time.deltaTime;
      if (_currentHealthValue <= 0)
        _currentHealthValue = 0;

      // show unhealth visuals
      if (_groundHealPS.isPlaying)
        _groundHealPS.Stop();
    }

    var currentValue = (float)(_currentHealthValue / maxHealthValue);
    UpdateLifeVisuals(currentValue);
    if (_currentHealthValue == 0 && !dead)
      KillPlayer();
  }

  public void KillPlayer() {
    dead = true;
    _dangerVolume.weight = 0f;
    _playerInputs.DeactivateInput();
    _playerInputs.enabled = false;
    _characterController.enabled = false; // character controller has own definition of position, so we
               // cant change position unless deactivated
    _thirdPersonController.enabled = false;
    _puppetMaster.Kill();
   // if (vfxDamages != null)
   // vfxDamages.SetBool("Kill", true);


    PlayerDeathEvent.Invoke(safe, _thirdPersonController.transform.position);

    Color[] pixels = struggle_map.GetPixels();
    for (int i = 0; i < pixels.Length; i++) {
      pixels[i].g = pixels[i].r;
    }
    struggle_map.SetPixels(pixels);
    Invoke(nameof(Resuscitate), 3f);
  }

  public void Resuscitate() {
    dead = false;
    player.transform.position = respawn_position;
    _puppetMaster.Teleport(respawn_position, player.transform.rotation, true);
    _puppetMaster.Resurrect();
    _currentHealthValue = maxHealthValue;
    _characterController.enabled = true;
    _thirdPersonController.enabled = true;
    _controllerAnimator.SetTrigger("KneelUp"); // RespawnAnim

   // if (vfxDamages != null)
   // vfxDamages.SetBool("Kill", false);

    Invoke(nameof(GiveControlBack), 1.5f);
    
  }

  void GiveControlBack() {
    _playerInputs.enabled = true;
    _playerInputs.ActivateInput();
  }

  /// <summary>
  /// Updates materials and puppet muscles to reflect loss or regain of life
  /// Dont do it on hips to avoid sway of whole root, and clamp legs and feet to
  /// still have walking effect even when losing life
  /// </summary>
  private void UpdateLifeVisuals(float currentValue) {
    float legValue;
    if (safe)
      currentValue = _healthGainCurve.Evaluate(currentValue);
    else
      currentValue = _healthLossCurve.Evaluate(currentValue);
    legValue = currentValue <= 0.6f ? 0.6f : currentValue; // Clamp on legs
    _puppetMaster.SetMuscleWeights(Muscle.Group.Head, currentValue,
                                   currentValue);
    _puppetMaster.SetMuscleWeights(Muscle.Group.Arm, currentValue,
                                   currentValue);
    _puppetMaster.SetMuscleWeights(Muscle.Group.Hand, currentValue,
                                   currentValue);
    _puppetMaster.SetMuscleWeights(HumanBodyBones.Chest, currentValue,
                                   currentValue);
    _puppetMaster.SetMuscleWeights(Muscle.Group.Leg, legValue, legValue);
    //_puppetMaster.SetMuscleWeights(Muscle.Group.Foot, legValue, legValue);

    if (!allowColorChange)
      return;
    Color currentColor = _healthLossGradient.Evaluate(currentValue);
    // Lumiere
    _light.color = currentColor;
    _light.intensity = Mathf.Lerp(minLightValue, maxLightValue, currentValue);

    // Oscillation
    currentOscillationModifier = 0.5f + currentValue;

    // Organs
    UpdateOrganMaterial(currentColor, _bodyGradient.Evaluate(currentValue));
    // Post Processing
    _dangerVolume.weight = _dangerAnimationCurve.Evaluate(currentValue);
  }

  private void UpdateAnimator() {
    var healthValue = _currentHealthValue / maxHealthValue;
    if (safe)
      healthValue = _healthGainCurve.Evaluate(healthValue);
    else
      healthValue = _healthLossCurve.Evaluate(healthValue);
    _controllerAnimator.SetFloat("Health", healthValue);
  }

  private void UpdateOscillation() {
    currentOscillationDuration += Time.deltaTime;
    if (currentOscillationDuration >= 3f)
      currentOscillationDuration = 0f;
    _light.range = (0.1f + lightOscillationAmplitudeCurve.Evaluate(
                               currentOscillationDuration *
                               currentOscillationModifier / 2f)) *
                   _originalLightRange;
  }

  private void UpdateOrganMaterial(Color c, Color bodyColor) {
    var mat = _organsRenderer.materials[0];
    var mat2 = _bodyRenderer.material;
    mat.SetColor("_Main_Color_1", c);
    mat.SetColor("_SSS_Color", c);
    bodyColor.a = 221f / 255f;
    mat2.SetColor("_BaseColor", bodyColor);
    _organsRenderer.materials[0] = mat;
  }

  private(int, int) GetStruggleUV() {
    Terrain terrain = Terrain.activeTerrain;
    float dx = player.transform.position.x - terrain.transform.position.x;
    float dz = player.transform.position.z - terrain.transform.position.z;
    int u = (int)(dx / terrain.terrainData.size.x * struggle_map.width);
    int v = (int)(dz / terrain.terrainData.size.z * struggle_map.height);
    return (u, v);
  }

  private void UpdateMovementSpeed() {
        if (_thirdPersonController == null) return;

        // Appliquer le multiplicateur uniquement sur la vitesse de course
        float multiplier = speedMultiplierActivated ? 4f : 1f;
        float currentSprintSpeed = normalSprintSpeed * multiplier;
        float currentMoveSpeed = normalMoveSpeed; // La vitesse de marche reste inchangée

        // (Optionnel) On met à jour la vitesse de marche dans le contrôleur
        _thirdPersonController.MoveSpeed = currentMoveSpeed;

        // Calcul de la santé normalisée (1 = vie max, 0 = mort)
        float normalizedHealth = _currentHealthValue / maxHealthValue;
        // Inverser horizontalement pour que 0 corresponde à vie max et 1 à la mort
        float invertedHealth = 1f - normalizedHealth;
        // Inverser verticalement la valeur de la courbe si besoin
        float speedFactor = 1f - speedCurve.Evaluate(invertedHealth);

        // Interpolation entre currentSprintSpeed et currentMoveSpeed
        // Quand speedFactor = 0 (vie max) -> SprintSpeed = currentSprintSpeed
        // Quand speedFactor = 1 (mort) -> SprintSpeed = currentMoveSpeed
        _thirdPersonController.SprintSpeed = Mathf.Lerp(currentSprintSpeed, currentMoveSpeed, speedFactor);
  }



}

}
