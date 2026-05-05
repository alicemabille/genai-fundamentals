//  read whole folder and import all
CALL apoc.load.directory("*.json", "file:///Users/alice/.Neo4jDesktop2/Data/dbmss/dbms-190679c2-4330-49a1-8984-b6f3c9a02da5/import",  {recursive: true})
YIELD value as files
UNWIND files as file
WITH "file://" + replace(file, '\\', '/') AS file
CALL apoc.periodic.iterate('
    CALL apoc.load.json($file)
    YIELD value AS k
  ',
  "
    // ---------------- KNOWLEDGE --------------------
    MERGE (know:Knowledge {id:k.id})
      ON CREATE SET 
        know.description = k.description,
        know.label = coalesce(k.label, ''), // sometimes label is missing and it's no big deal
        know.type = k.type


    // ------------------- DIAGNOSIS -----------------------
    UNWIND k.intentions.diagnostiquer.modalites AS d

    // using coalesce allows for null values. This way this MERGE command will adapt to QCM and cloze
    // by calling for attributes of both and retrieving accordingly.
    MERGE (dia:Diagnosis {id: k.id + '_' + d.id})
      ON CREATE SET
        dia.label = d.label, 
        dia.type = d.type,
        dia.question = coalesce(d.contenu.question, ''),
        dia.context = coalesce(d.contenu.context, ''),
        dia.hint = coalesce(d.contenu.hint, ''),
        dia.instruction = coalesce(d.contenu.instruction, ''), //cloze
        dia.sentence = coalesce(d.contenu.sentence, ''), //cloze
        dia.word_bank = coalesce(d.contenu.word_bank, ''), //cloze
        dia.correct_answer = coalesce(d.contenu.correct_answer, ''), //cloze
        dia.success_feedback = coalesce(d.contenu.success_feedback, ''), //cloze
        dia.teacher_note = coalesce(d.contenu.teacher_note, '') //cloze
    MERGE (dia)-[:DIAGNOSES]->(know)

    UNWIND d.contenu.options AS o
    MERGE (opt:Answer {id:k.id + '_' + d.id + '_' + o.id})
      ON CREATE SET
        opt.text = o.text,
        opt.is_correct = o.is_correct
    MERGE (opt)-[:ANSWERS]->(dia)

    UNWIND d.contenu.distractors_feedback AS df
    MERGE (f:Feedback {id:k.id + '_' + d.id + '_' + coalesce(df.option_id, df.wrong_answer)})
      ON CREATE SET
        f.wrong_answer = coalesce(df.wrong_answer, ''), //cloze
        f.misconception = coalesce(df.misconception, ''),
        f.feedback = coalesce(df.feedback, '')


    // ------------- PRACTICE ----------------------
    UNWIND k.intentions.pratiquer.modalites AS p
    // using coalesce allows for null values. This way this MERGE command will adapt to QCM and cloze
    // by calling for attributes of both and retrieving accordingly.
    MERGE (pra:Practice {id: k.id + '_' + p.id})
      ON CREATE SET
        pra.label = p.label, 
        pra.type = p.type,
        pra.question =  coalesce(p.contenu.question, ''), //QCM
        pra.context =   coalesce(p.contenu.context, ''), //QCM
        pra.hint =      coalesce(p.contenu.hint, ''), //QCM
        pra.instruction =  coalesce(p.contenu.instruction, ''), //cloze
        pra.sentence =  coalesce(p.contenu.sentence, ''), //cloze
        pra.word_bank =  coalesce(p.contenu.word_bank, ''), //cloze
        pra.correct_answer =  coalesce(p.contenu.correct_answer, ''), //cloze
        pra.success_feedback =  coalesce(p.contenu.success_feedback, ''), //cloze
        pra.teacher_note =  coalesce(d.contenu.teacher_note, '') //cloze
    MERGE (pra)-[:PRACTICES]->(know)


    UNWIND p.contenu.options AS op
    MERGE (optp:Answer {id:         k.id + '_' + p.id + '_' + op.id})
      ON CREATE SET
        optp.text = op.text,
        optp.is_correct = op.is_correct
    MERGE (optp)-[:ANSWERS]->(pra)

    UNWIND p.contenu.distractors_feedback AS dfp
    MERGE (fp:Feedback {id:k.id + '_' + p.id + '_' + coalesce(dfp.option_id, dfp.wrong_answer)})
      ON CREATE SET
        fp.wrong_answer = coalesce(dfp.wrong_answer, ''), //cloze
        fp.misconception = coalesce(dfp.misconception, ''), //QCM
        fp.feedback = coalesce(dfp.feedback, '') //QCM


    // ------------- APPLY ----------------------
    UNWIND k.intentions.appliquer.modalites AS a
    // using coalesce allows for null values. This way this MERGE command will adapt to QCM and cloze
    // by calling for attributes of both and retrieving accordingly.
    MERGE (app:Apply {id: k.id + '_' + a.id})
      ON CREATE SET
        app.label = a.label,
        app.type = a.type,
        app.question =        coalesce(a.contenu.question, ''), //QCM
        app.context =         coalesce(a.contenu.context, ''), //QCM
        app.hint =            coalesce(a.contenu.hint, ''), //QCM
        app.instruction =     coalesce(a.contenu.instruction, ''), //cloze
        app.sentence =        coalesce(a.contenu.sentence, ''), //cloze
        app.word_bank =       coalesce(a.contenu.word_bank, ''), //cloze
        app.correct_answer =  coalesce(a.contenu.correct_answer, ''), //cloze
        app.success_feedback = coalesce(a.contenu.success_feedback, ''), //cloze
        app.teacher_note =    coalesce(a.contenu.teacher_note, '') //cloze
    MERGE (app)-[:APPLIES]->(know)

    UNWIND a.contenu.options AS oa
    MERGE (opta:Answer {id: k.id + '_' + a.id + '_' + oa.id})
      ON CREATE SET
        opta.text = oa.text,
        opta.is_correct = oa.is_correct
    MERGE (opta)-[:ANSWERS]->(app)

    UNWIND a.contenu.distractors_feedback AS dfa
    MERGE (fa:Feedback {id: k.id + '_' + a.id + '_' + coalesce(dfa.option_id, dfa.wrong_answer)})
      ON CREATE SET
        fa.wrong_answer =  coalesce(dfa.wrong_answer, ''), //cloze
        fa.misconception = coalesce(dfa.misconception, ''), //QCM
        fa.feedback =      coalesce(dfa.feedback, '') //QCM
  ",
   {batchSize:10000, parallel:true, params: {file: file}})

YIELD batches, total, updateStatistics
RETURN batches, total, updateStatistics;


// --------- LINK FEEDBACKS TO ANSWERS --------------
MATCH (f:Feedback)
MERGE (f)-[:FEEDS_BACK_FROM]->(:Answer {id: f.id});

