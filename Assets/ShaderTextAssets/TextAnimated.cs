using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Text;
using System.Linq;
using UnityEngine.UI;
using UnityEditor;

public class TextAnimated : Text
{
    // Start is called before the first frame update
    private const char delimiter = '`';
    public Material baseMaterial;
    private float[] animateVerts = new float[16];

    private GameObject trackedObject;
    private Vector3 trackedPos;

    public void Start()
    {
        if (trackedObject == null)
        {
            trackedPos = Vector3.zero;
        }
        else
        {
            trackedPos = trackedObject.transform.position;
        }
        this.material = Material.Instantiate(this.baseMaterial);
        //this.SetText("`animated` not animated. `Woooo!` less woo...");
    }

    
    public void SetText(string newText)
    {        
        if (newText.Contains(delimiter))
        {
            string[] substrings = newText.Split(delimiter);
            int charCount = 0;
            int spaces = 0; // Whitespace doesn't have a glyph, so we need to deduct from the vertex indices when counting characters.
            StringBuilder output = new StringBuilder(); // The actual output text should not have the delimiter.

            for (int s = 0; s < substrings.Length; s++)
            {
                output.Append(substrings[s]);
                if (s == substrings.Length - 1 && s % 2 == 0) // The text to animate will always be an odd-numbered substring,
                    break;                                    // so if we're on an even-numbered substring with no corresponding odd-numbered one, we can just stop.

                spaces += substrings[s].Count(c => char.IsWhiteSpace(c));

                this.animateVerts[s] = charCount + substrings[s].Length - spaces; // This gives the index of the character at the start/end of an animated text region, accounting for whitespace.
                this.animateVerts[s] =
                    this.animateVerts[s] * 4 + // Each glyph has 4 vertices (TL->TR->BR->BL), so this gives the actual vertex index.
                    (s % 2 == 1 ? -1 : 0); // For the ends of animated text substrings, that index will be the first index after the substring, so add -1 to get the last index of the substring instead.

                charCount += substrings[s].Length;
            }
            this.animateVerts[substrings.Length] = -1; // We'll use a -1 index so the shader knows where the valid data ends, since we don't ever clear out this array.
            this.text = output.ToString();
        }
        else
        {
            this.animateVerts[0] = -1;
            this.text = newText;
        }
    }

    

    public void SetTrackedObject(GameObject obj)
    {
        trackedObject = obj;
        trackedPos = trackedObject.transform.position;
    }

    protected override void OnPopulateMesh(VertexHelper toFill)
    {
        base.OnPopulateMesh(toFill);
        //this.material.SetFloatArray("_AnimateVerts", this.animateVerts);

        
        //Hack job to get float array into shader graph shader

        Texture2D tex = new Texture2D(1, animateVerts.Length, TextureFormat.RGBAFloat, false);
        for (int i = 0; i < animateVerts.Length; i++) {
            Color c = new Color(animateVerts[i], animateVerts[i], animateVerts[i], animateVerts[i]);
            tex.SetPixel(0, i, c);
            }

        this.material.SetTexture("_TexturedVerts", tex);
    }
    

    // Update is called once per frame
    void Update()
    {
        if (trackedObject != null)
        {
            trackedPos = new Vector4(trackedObject.transform.position.x, trackedObject.transform.position.y, trackedObject.transform.position.z, trackedObject.transform.rotation.w);
        }
        this.material.SetVector("_ObjWorldPos", this.transform.position);
    }
}


[CustomEditor(typeof(TextAnimated))]
public class TextAnimatedEditor : UnityEditor.UI.TextEditor
{
    private SerializedProperty baseMaterialProp;

    protected override void OnEnable()
    {
        base.OnEnable();
        this.baseMaterialProp = serializedObject.FindProperty("baseMaterial");
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        serializedObject.Update();
        EditorGUILayout.PropertyField(this.baseMaterialProp, new GUIContent("Base Material"));
        serializedObject.ApplyModifiedProperties();
    }
}