using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class ProceduralQuad : MonoBehaviour
{
    [SerializeField]
    private float width = 1;

    [SerializeField]
    private float height = 1;

    [SerializeField]
    private float noiseScale = 1; // A scale for the noise to affect the vertices' y position

    [SerializeField]
    private float vertexOffset = 0.1f; // Controls the displacement of vertices along the normals

    private Mesh mesh;

    private void Awake()
    {
        mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;

        CreateShape();
    }

    private float NoiseFunction(float x, float z)
    {
        // Simple perlin noise, replace this with your own noise function if needed
        return Mathf.PerlinNoise(x, z);
    }

    private void CreateShape()
{
    Vector3[] vertices = new Vector3[4];
    Vector2[] uvs = new Vector2[4];
    int[] triangles = new int[6];

    float halfWidth = width * 0.5f;
    float halfHeight = height * 0.5f;

    for (int i = 0; i < 4; i++)
    {
        float x = i % 2 == 0 ? 0 : width;
        float z = i < 2 ? 0 : height;

        float noise = NoiseFunction(x, z) * noiseScale;
        float yOffset = Random.Range(-vertexOffset, vertexOffset);

        vertices[i] = new Vector3(x - halfWidth, yOffset, z - halfHeight);
        uvs[i] = new Vector2(x / width, z / height);
    }

    triangles[0] = 0;
    triangles[1] = 2;
    triangles[2] = 1;
    triangles[3] = 2;
    triangles[4] = 3;
    triangles[5] = 1;

    mesh.Clear();
    mesh.vertices = vertices;
    mesh.uv = uvs;
    mesh.triangles = triangles;
    mesh.RecalculateNormals();
}

}
