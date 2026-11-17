Prepare a estrutura inicial do projeto Swift “Argus” no repositório aberto. O projeto será um MCP Server e um macOS Helper; o MCP client, como Kilo Code, é externo. O Helper manterá uma sessão WebPage do WebKit na main actor.

Antes de alterar arquivos:
1. Inspecione o repositório, as ferramentas instaladas e qualquer código existente.
2. Preserve o que já estiver correto; não substitua arquivos ou configurações sem necessidade.
3. Verifique se o SDK de macOS e o toolchain disponíveis expõem a API WebPage necessária. Não presuma que ela existe nem a substitua por WKWebView silenciosamente.
4. Resuma brevemente a estrutura proposta e eventuais limitações do ambiente.

Depois, prepare um scaffold funcional, sem implementar ainda a automação completa do browser:

- Organize os componentes do MCP Server e do macOS Helper em diretórios e targets separados, com responsabilidades claras.
- Use Swift Package Manager se for apropriado para a estrutura e as APIs necessárias. Se o Helper precisar de um target ou configuração de app macOS que o SPM não atenda adequadamente, explique e use a alternativa mais simples. Evite introduzir dois sistemas de build sem necessidade.
- Crie os arquivos de entrada e os tipos iniciais para MCP, IPC e Browser, sem misturar suas responsabilidades.
- Crie um esboço do dono da sessão Browser, isolado no Helper e marcado para operar na main actor. Não invente chamadas ou assinaturas da API WebPage: confira a documentação disponível no SDK instalado e deixe TODOs explícitos quando não puder confirmar uma assinatura.
- Escolha e documente um formato inicial de mensagens IPC com IDs de requisição, método, argumentos, resposta e erro. Não crie ainda um socket inseguro ou um protocolo improvisado sem validação.
- Inclua testes mínimos para os tipos e a validação básica de mensagens.
- Configure `.gitignore`, nomes consistentes e estrutura adequada ao desenvolvimento pelo terminal e VS Code.
- Atualize ou crie um README com pré-requisitos confirmados, comandos reais de build/test, estrutura do projeto, arquitetura e limitações. Não apresente comandos como testados se não os executou.
- Preserve documentos existentes e ajuste-os somente se encontrar instruções contraditórias.

Não implemente ferramentas MCP completas, navegação, execução de JavaScript, automação de sites, acesso a shell ou leitura de arquivos do usuário nesta etapa. O objetivo é deixar uma base organizada, compilável quando o SDK disponível permitir, e pronta para desenvolvimento incremental.

Critérios de conclusão:
- A estrutura e os arquivos principais estão criados.
- Os limites entre MCP Server, IPC e Helper estão documentados.
- Os testes disponíveis foram executados.
- Os comandos de build/test foram executados ou estão claramente marcados como não verificados.
- O relatório final lista arquivos criados/alterados, comandos executados e resultados, além de bloqueios relacionados ao SDK ou ao ambiente.
