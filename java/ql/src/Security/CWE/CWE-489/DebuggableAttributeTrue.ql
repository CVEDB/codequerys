/**
 * @name Android debuggable attribute enabled
 * @description An enabled debugger can allow for entry points in the application or reveal sensitive information.
 * @kind problem
 * @problem.severity warning
 * @security-severity 7.2
 * @id java/android/debuggable-attribute-enabled
 * @tags security
 *       external/cwe/cwe-489
 * @precision very-high
 */

import java
import semmle.code.xml.AndroidManifest

from AndroidXmlAttribute androidXmlAttr
where
  androidXmlAttr.getName() = "debuggable" and
  androidXmlAttr.getValue() = "true" and
  not androidXmlAttr.getLocation().getFile().getRelativePath().matches("%/build%")
select androidXmlAttr, "The 'android:debuggable' attribute is enabled."
