using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.AI;


public class FieldOfView : MonoBehaviour {

	private UnityEngine.AI.NavMeshAgent agent;
	//[HideInInspector]
	public Animator animator;

	private float behaviorCooldown = 2f;
	private float currentBehaviorCooldown = 0f;


	[Header("Paramètres créatures")]
	public bool isInPursuit = false;
	private float currentPursuitTimer = 0f;
	private float maxPursuitTimer = 5f;


	public enum BehaviourState
    {
        Idle,
        Pursuit,
        Wander,
		Stand
    };

	public BehaviourState state = BehaviourState.Idle;
	public BehaviourState lastState ;

	public float speedNumber ;
	public Vector2 speedMinMax = new Vector2(1,2);

	public Transform activeTarget;
	public float distanceWithActiveTarget;
	public float distanceDecision;

	public float chanceNumber ;

	public float walkRadius = 30;

	
	public float viewRadius;
	[Range(0,360)]
	public float viewAngle;
	public LayerMask targetMask;
	public LayerMask obstacleMask;

	public GameObject LookAtObj;

	//[HideInInspector]
	public List<Transform> visibleTargets = new List<Transform>();

	private float meshResolution = 1;
	private int edgeResolveIterations = 1;
	private float edgeDstThreshold = 1;
	public MeshFilter viewMeshFilter;
	Mesh viewMesh;



	void Start() {
		
		viewMesh = new Mesh ();
		viewMesh.name = "View Mesh";
		viewMeshFilter.mesh = viewMesh;


			//// A passer dans UPDATE with delay
		StartCoroutine ("FindTargetsWithDelay", .2f);
		StartCoroutine ("CalculateDistanceWithActiveTargetWithDelay", .2f);
		//StartCoroutine ("RandomChanceWithDelay", Random.Range(1,5));

		agent = GetComponent<UnityEngine.AI.NavMeshAgent>();
		//animator = this.gameObject.transform.GetChild(0).GetComponent<Animator>();
	}



	void Update()
    {  

		LookAtTarget();
		TrackingTarget();		

		if (currentBehaviorCooldown >= behaviorCooldown){
			Behavior();
			currentBehaviorCooldown = 0;
		}
		else{
			currentBehaviorCooldown += Time.deltaTime ;
		}

		if (isInPursuit){
			currentPursuitTimer += Time.deltaTime;
		}
		
		
    }



	IEnumerator RandomChanceWithDelay(float delay) {
		while (true) {
			yield return new WaitForSeconds (delay);
			RandomChance();
		}
	}
	
	IEnumerator FindTargetsWithDelay(float delay) {
		while (true) {
			yield return new WaitForSeconds (delay);
			FindVisibleTargets();
		}
	}

	IEnumerator CalculateDistanceWithActiveTargetWithDelay(float delay) {
		while (true) {
			yield return new WaitForSeconds (delay);
			CalculateDistanceWithActiveTarget();
		}
	}



	void LateUpdate() {
		DrawFieldOfView();
	}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	void LookAtTarget(){
		LookAtObj = GameObject.FindWithTag("LookAtObject");
		if (activeTarget == null){ 
  			return;
			}	
		LookAtObj.transform.position = activeTarget.position;
	}

	void TrackingTarget(){
		if (visibleTargets.Count == 0){
 		 return;
		}

		int visibleTargetsNumber = visibleTargets.Count;

		if(visibleTargetsNumber > 0){
			activeTarget = visibleTargets[visibleTargetsNumber-1];
		} 

	}



	void Behavior(){
		
		float dist = agent.remainingDistance;
			if (state != BehaviourState.Idle ){
	
				if (dist!=Mathf.Infinity && agent.pathStatus==NavMeshPathStatus.PathComplete && agent.remainingDistance<=3.25f){
					state = lastState;
					Idle();
					return;
				}
				else if (isInPursuit && currentPursuitTimer >= maxPursuitTimer){
					state = lastState;
					Idle();
					isInPursuit = false;
					currentPursuitTimer = 0f;
					return;
				}
			}
			else{
				RandomChance();
				RandomSpeed();

				if(chanceNumber > 50 && distanceWithActiveTarget > distanceDecision || agent.velocity != Vector3.zero && distanceWithActiveTarget < distanceDecision){
					state = lastState;
					Pursuit(activeTarget);
					
				}
				else{
					state = lastState;
					Wander();
				}

			}

		
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



	void Idle(){
		animator.Play("Base Layer.Idle 1", 0, 0f);
		if (chanceNumber > 90){
			animator.Play("Base Layer.Idle Stand", 0, 0f);
		}

		state = BehaviourState.Idle;
	}
	void Pursuit(Transform pursuitTarget){
		animator.Play("Base Layer.Idle 2", 0, 0f);
		isInPursuit = true;
		agent.speed = speedNumber * 2;
		agent.SetDestination(pursuitTarget.position);
		state = BehaviourState.Pursuit;
	}

	void Wander(){
		animator.Play("Base Layer.Idle 2", 0, 0f);
		Vector3 randomDirection = Random.insideUnitSphere * walkRadius;

		randomDirection += transform.position;
		NavMeshHit hit;
		NavMesh.SamplePosition(randomDirection, out hit, walkRadius, 1);
		Vector3 finalPosition = hit.position;

		agent.speed = speedNumber;
		agent.SetDestination(finalPosition);
		state = BehaviourState.Wander;
	}

	void Stand(){
		animator.Play("Base Layer.Idle Stand", 0, 0f);
		state = BehaviourState.Stand;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	void CalculateDistanceWithActiveTarget(){
		if (activeTarget == null){ 
  			// Skip if we have no target
  			return;
			}	

		distanceWithActiveTarget = Vector3.Distance(this.transform.position, activeTarget.position);
	}

	void RandomChance() {
		chanceNumber = Random.Range(0,100);

	}
	void RandomSpeed() {
		speedNumber = Random.Range(speedMinMax.x,speedMinMax.y);
	}

	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	void FindVisibleTargets() {
		visibleTargets.Clear ();
		Collider[] targetsInViewRadius = Physics.OverlapSphere (transform.position, viewRadius, targetMask);

		for (int i = 0; i < targetsInViewRadius.Length; i++) {
			Transform target = targetsInViewRadius [i].transform;
			Vector3 dirToTarget = (target.position - transform.position).normalized;
			if (Vector3.Angle (transform.forward, dirToTarget) < viewAngle / 2) {
				float dstToTarget = Vector3.Distance (transform.position, target.position);
				if (!Physics.Raycast (transform.position, dirToTarget, dstToTarget, obstacleMask)) {
					visibleTargets.Add (target);
				}
			}
		}
	}

	void DrawFieldOfView() {
		int stepCount = Mathf.RoundToInt(viewAngle * meshResolution);
		float stepAngleSize = viewAngle / stepCount;
		List<Vector3> viewPoints = new List<Vector3> ();
		ViewCastInfo oldViewCast = new ViewCastInfo ();
		for (int i = 0; i <= stepCount; i++) {
			float angle = transform.eulerAngles.y - viewAngle / 2 + stepAngleSize * i;
			ViewCastInfo newViewCast = ViewCast (angle);

			if (i > 0) {
				bool edgeDstThresholdExceeded = Mathf.Abs (oldViewCast.dst - newViewCast.dst) > edgeDstThreshold;
				if (oldViewCast.hit != newViewCast.hit || (oldViewCast.hit && newViewCast.hit && edgeDstThresholdExceeded)) {
					EdgeInfo edge = FindEdge (oldViewCast, newViewCast);
					if (edge.pointA != Vector3.zero) {
						viewPoints.Add (edge.pointA);
					}
					if (edge.pointB != Vector3.zero) {
						viewPoints.Add (edge.pointB);
					}
				}

			}


			viewPoints.Add (newViewCast.point);
			oldViewCast = newViewCast;
		}

		int vertexCount = viewPoints.Count + 1;
		Vector3[] vertices = new Vector3[vertexCount];
		int[] triangles = new int[(vertexCount-2) * 3];

		vertices [0] = Vector3.zero;
		for (int i = 0; i < vertexCount - 1; i++) {
			vertices [i + 1] = transform.InverseTransformPoint(viewPoints [i]);

			if (i < vertexCount - 2) {
				triangles [i * 3] = 0;
				triangles [i * 3 + 1] = i + 1;
				triangles [i * 3 + 2] = i + 2;
			}
		}

		viewMesh.Clear ();

		viewMesh.vertices = vertices;
		viewMesh.triangles = triangles;
		viewMesh.RecalculateNormals ();
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	EdgeInfo FindEdge(ViewCastInfo minViewCast, ViewCastInfo maxViewCast) {
		float minAngle = minViewCast.angle;
		float maxAngle = maxViewCast.angle;
		Vector3 minPoint = Vector3.zero;
		Vector3 maxPoint = Vector3.zero;

		for (int i = 0; i < edgeResolveIterations; i++) {
			float angle = (minAngle + maxAngle) / 2;
			ViewCastInfo newViewCast = ViewCast (angle);

			bool edgeDstThresholdExceeded = Mathf.Abs (minViewCast.dst - newViewCast.dst) > edgeDstThreshold;
			if (newViewCast.hit == minViewCast.hit && !edgeDstThresholdExceeded) {
				minAngle = angle;
				minPoint = newViewCast.point;
			} else {
				maxAngle = angle;
				maxPoint = newViewCast.point;
			}
		}

		return new EdgeInfo (minPoint, maxPoint);
	}


	ViewCastInfo ViewCast(float globalAngle) {
		Vector3 dir = DirFromAngle (globalAngle, true);
		RaycastHit hit;

		if (Physics.Raycast (transform.position, dir, out hit, viewRadius, obstacleMask)) {
			return new ViewCastInfo (true, hit.point, hit.distance, globalAngle);
		} else {
			return new ViewCastInfo (false, transform.position + dir * viewRadius, viewRadius, globalAngle);
		}
	}

	public Vector3 DirFromAngle(float angleInDegrees, bool angleIsGlobal) {
		if (!angleIsGlobal) {
			angleInDegrees += transform.eulerAngles.y;
		}
		return new Vector3(Mathf.Sin(angleInDegrees * Mathf.Deg2Rad),0,Mathf.Cos(angleInDegrees * Mathf.Deg2Rad));
	}

	public struct ViewCastInfo {
		public bool hit;
		public Vector3 point;
		public float dst;
		public float angle;

		public ViewCastInfo(bool _hit, Vector3 _point, float _dst, float _angle) {
			hit = _hit;
			point = _point;
			dst = _dst;
			angle = _angle;
		}
	}

	public struct EdgeInfo {
		public Vector3 pointA;
		public Vector3 pointB;

		public EdgeInfo(Vector3 _pointA, Vector3 _pointB) {
			pointA = _pointA;
			pointB = _pointB;
		}
	}

}